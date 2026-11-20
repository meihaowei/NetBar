import AppKit

let canvas: CGFloat = 1024

func drawIcon() {
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: canvas, height: canvas).fill()

    let tile = NSRect(x: 100, y: 100, width: 824, height: 824)
    let tilePath = NSBezierPath(roundedRect: tile, xRadius: 182, yRadius: 182)
    tilePath.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.035, green: 0.09, blue: 0.18, alpha: 1),
        NSColor(calibratedRed: 0.00, green: 0.36, blue: 0.44, alpha: 1),
    ])
    gradient?.draw(in: tilePath, angle: -48)

    NSColor.white.withAlphaComponent(0.045).setStroke()
    for x in stride(from: 188.0, through: 840.0, by: 163.0) {
        let grid = NSBezierPath()
        grid.lineWidth = 3
        grid.move(to: NSPoint(x: x, y: 100))
        grid.line(to: NSPoint(x: x, y: 924))
        grid.stroke()
    }

    let sheen = NSBezierPath()
    sheen.move(to: NSPoint(x: 100, y: 720))
    sheen.curve(
        to: NSPoint(x: 924, y: 780),
        controlPoint1: NSPoint(x: 360, y: 650),
        controlPoint2: NSPoint(x: 650, y: 870)
    )
    sheen.line(to: NSPoint(x: 924, y: 924))
    sheen.line(to: NSPoint(x: 100, y: 924))
    sheen.close()
    NSColor.white.withAlphaComponent(0.045).setFill()
    sheen.fill()

    NSColor.white.withAlphaComponent(0.15).setStroke()
    let border = NSBezierPath(
        roundedRect: tile.insetBy(dx: 8, dy: 8),
        xRadius: 174,
        yRadius: 174
    )
    border.lineWidth = 4
    border.stroke()

    func drawArrow(centerX: CGFloat, pointsUp: Bool) {
        let shaftTop: CGFloat = pointsUp ? 650 : 450
        let shaftBottom: CGFloat = pointsUp ? 385 : 685
        let tipY: CGFloat = pointsUp ? 724 : 300
        let shoulderY: CGFloat = pointsUp ? 610 : 430
        let shoulderOffset: CGFloat = 82

        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowBlurRadius = 18
        shadow.shadowOffset = NSSize(width: 0, height: -9)
        shadow.set()
        NSColor.white.setFill()
        NSColor.white.setStroke()

        let shaft = NSBezierPath()
        shaft.lineWidth = 56
        shaft.lineCapStyle = .round
        shaft.move(to: NSPoint(x: centerX, y: shaftBottom))
        shaft.line(to: NSPoint(x: centerX, y: shaftTop))
        shaft.stroke()

        let head = NSBezierPath()
        head.move(to: NSPoint(x: centerX - shoulderOffset, y: shoulderY))
        head.line(to: NSPoint(x: centerX, y: tipY))
        head.line(to: NSPoint(x: centerX + shoulderOffset, y: shoulderY))
        head.close()
        head.fill()
    }

    drawArrow(centerX: 348, pointsUp: false)
    drawArrow(centerX: 676, pointsUp: true)
    NSGraphicsContext.restoreGraphicsState()
}

func render(size: Int, path: String) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        throw NSError(domain: "NetBarIcon", code: 1)
    }

    bitmap.size = NSSize(width: size, height: size)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context
    let scale = CGFloat(size) / canvas
    context.cgContext.scaleBy(x: scale, y: scale)
    drawIcon()
    context.flushGraphics()

    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "NetBarIcon", code: 2)
    }
    try data.write(to: URL(fileURLWithPath: path), options: .atomic)
}

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: make-icon <output.iconset>\n", stderr)
    exit(64)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

let variants: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024),
]

for (name, size) in variants {
    try render(size: size, path: output.appendingPathComponent(name).path)
}
