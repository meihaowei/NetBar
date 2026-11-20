import AppKit
import Darwin

private final class StatusView: NSView {
    private let lineHeight: CGFloat = 10.5
    private var topText = ""
    private var bottomText = ""

    override var isFlipped: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    func update(top: String, bottom: String) {
        topText = top
        bottomText = bottom
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let font = NSFont.monospacedSystemFont(ofSize: 9.5, weight: .medium)
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .left
        paragraph.minimumLineHeight = lineHeight
        paragraph.maximumLineHeight = lineHeight
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]

        let blockHeight = lineHeight * 2
        let top = floor((bounds.height - blockHeight) / 2) + 5
        let lines = [topText, bottomText]
        for (index, text) in lines.enumerated() {
            let width = (text as NSString).size(withAttributes: attributes).width
            let rect = NSRect(
                x: floor((bounds.width - width) / 2),
                y: top + CGFloat(index) * lineHeight,
                width: ceil(width),
                height: lineHeight
            )
            (text as NSString).draw(in: rect, withAttributes: attributes)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private let statusView = StatusView()
    private var previousNetwork: (up: UInt64, down: UInt64, time: TimeInterval)?
    private var previousCPU: (busy: UInt64, total: UInt64)?

    private let speedItem = NSMenuItem()
    private let cpuItem = NSMenuItem()
    private let memoryItem = NSMenuItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 94)
        statusItem.button?.toolTip = "NetBar：网速、CPU、内存"
        statusItem.button?.addSubview(statusView)
        statusView.translatesAutoresizingMaskIntoConstraints = false
        if let button = statusItem.button {
            NSLayoutConstraint.activate([
                statusView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
                statusView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                statusView.topAnchor.constraint(equalTo: button.topAnchor),
                statusView.bottomAnchor.constraint(equalTo: button.bottomAnchor),
            ])
        }

        let menu = NSMenu()
        menu.autoenablesItems = false
        speedItem.isEnabled = false
        cpuItem.isEnabled = false
        memoryItem.isEnabled = false
        menu.addItem(speedItem)
        menu.addItem(cpuItem)
        menu.addItem(memoryItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "退出 NetBar", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        statusItem.menu = menu

        update()
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    @objc private func update() {
        let now = ProcessInfo.processInfo.systemUptime
        let network = networkBytes()
        var downRate = 0.0
        var upRate = 0.0

        if let previous = previousNetwork {
            let seconds = now - previous.time
            if seconds > 0 {
                downRate = Double(network.down >= previous.down ? network.down - previous.down : 0) / seconds
                upRate = Double(network.up >= previous.up ? network.up - previous.up : 0) / seconds
            }
        }
        previousNetwork = (network.up, network.down, now)

        let cpu = cpuUsage()
        let memory = memoryUsage()
        let down = Self.rate(downRate)
        let up = Self.rate(upRate)
        let downField = Self.pad(down, to: 5)
        let upField = Self.pad(up, to: 5)
        let cpuField = String(format: "%3d%%", Int(cpu.rounded()))
        let memoryField = String(format: "%3d%%", Int(memory.percent.rounded()))

        statusView.update(
            top: "↑\(upField)  \(cpuField)",
            bottom: "↓\(downField)  \(memoryField)"
        )
        statusItem.button?.toolTip = "下载 \(down)/s，上传 \(up)/s\nCPU \(Self.percent(cpu))\n内存 \(Self.size(memory.used)) / \(Self.size(memory.total))"
        speedItem.title = "网速    ↓ \(down)/s    ↑ \(up)/s"
        cpuItem.title = "CPU     \(Self.percent(cpu))"
        memoryItem.title = "内存    \(Self.size(memory.used)) / \(Self.size(memory.total))  ·  \(Self.percent(memory.percent))"
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func networkBytes() -> (up: UInt64, down: UInt64) {
        var addresses: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addresses) == 0, let first = addresses else { return (0, 0) }
        defer { freeifaddrs(addresses) }

        var up: UInt64 = 0
        var down: UInt64 = 0
        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let interface = pointer?.pointee {
            defer { pointer = interface.ifa_next }
            guard let address = interface.ifa_addr,
                  address.pointee.sa_family == UInt8(AF_LINK),
                  let rawName = interface.ifa_name,
                  let data = interface.ifa_data else { continue }

            let name = String(cString: rawName)
            let excluded = ["lo", "awdl", "llw", "utun", "gif", "stf", "bridge", "ap", "anpi", "vmenet"]
            if excluded.contains(where: { name.hasPrefix($0) }) { continue }

            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            up &+= UInt64(stats.ifi_obytes)
            down &+= UInt64(stats.ifi_ibytes)
        }
        return (up, down)
    }

    private func cpuUsage() -> Double {
        var cpuCount: natural_t = 0
        var cpuInfo: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(
            mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &cpuInfo, &infoCount
        )
        guard result == KERN_SUCCESS, let cpuInfo else { return 0 }
        defer {
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: cpuInfo),
                vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size)
            )
        }

        var busy: UInt64 = 0
        var total: UInt64 = 0
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * Int(CPU_STATE_MAX)
            let user = UInt64(cpuInfo[base + Int(CPU_STATE_USER)])
            let system = UInt64(cpuInfo[base + Int(CPU_STATE_SYSTEM)])
            let nice = UInt64(cpuInfo[base + Int(CPU_STATE_NICE)])
            let idle = UInt64(cpuInfo[base + Int(CPU_STATE_IDLE)])
            busy += user + system + nice
            total += user + system + nice + idle
        }

        guard let previous = previousCPU else {
            previousCPU = (busy, total)
            return 0
        }
        previousCPU = (busy, total)
        guard total > previous.total else { return 0 }
        return Double(busy - previous.busy) / Double(total - previous.total) * 100
    }

    private func memoryUsage() -> (used: UInt64, total: UInt64, percent: Double) {
        let total = ProcessInfo.processInfo.physicalMemory
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (0, total, 0) }

        let pageSize = UInt64(vm_kernel_page_size)
        let available = UInt64(stats.free_count + stats.inactive_count + stats.speculative_count) * pageSize
        let used = total > available ? total - available : 0
        return (used, total, total == 0 ? 0 : Double(used) / Double(total) * 100)
    }

    private static func rate(_ bytes: Double) -> String {
        guard bytes >= 1 else { return "0B" }
        let units = ["B", "K", "M", "G", "T"]
        var value = bytes
        var unit = 0
        while value >= 1000, unit < units.count - 1 {
            value /= 1000
            unit += 1
        }
        if unit == 0 { return "\(Int(value))B" }
        let precision = value >= 100 ? 0 : (value >= 10 ? 1 : 2)
        return String(format: "%.\(precision)f%@", value, units[unit])
    }

    private static func pad(_ value: String, to width: Int) -> String {
        String(repeating: " ", count: max(0, width - value.count)) + value
    }

    private static func size(_ bytes: UInt64) -> String {
        let value = Double(bytes)
        if bytes >= 1_000_000_000 { return String(format: "%.1f GB", value / 1_000_000_000) }
        if bytes >= 1_000_000 { return String(format: "%.0f MB", value / 1_000_000) }
        return String(format: "%.0f KB", value / 1000)
    }

    private static func percent(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
}

@main
struct NetBar {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
