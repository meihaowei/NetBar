# NetBar

**Network speed, CPU, and memory in one compact macOS menu bar item.**

[简体中文](README.zh-CN.md) · [Download preview](https://github.com/meihaowei/NetBar/releases/download/v1.0.6-local/NetBar-1.0.6-local.dmg) · [Source code](https://github.com/meihaowei/NetBar)

NetBar is a small native AppKit utility. It has no Dock icon, no account, no
analytics, and no background network requests.

## What it looks like

![NetBar in the macOS menu bar](docs/netbar-status.png)

The menu bar uses two compact rows:

| Row | Left | Right |
| --- | --- | --- |
| Top | `↑` upload speed | CPU usage |
| Bottom | `↓` download speed | Memory usage |

The fields use fixed character widths, so the item does not jump sideways when
numbers change. Network rates are updated once per second.

Click the status item to see exact values:

![NetBar detail menu](docs/netbar-menu.png)

The menu shows the current download/upload rates, CPU percentage, used and
total memory, and a quit command.

## Install

Requirements:

- macOS 12 or later
- Apple Silicon or Intel Mac

1. Download the [current preview DMG](https://github.com/meihaowei/NetBar/releases/download/v1.0.6-local/NetBar-1.0.6-local.dmg).
2. Open the DMG and drag `NetBar.app` into `Applications`.
3. Launch NetBar from Applications. It immediately appears in the menu bar.

> [!IMPORTANT]
> The preview DMG is ad-hoc signed and has not been notarized by Apple. macOS
> may block it on another computer. A trusted public build requires a Developer
> ID signature and notarization.

## Build from source

The project requires Swift 6, Xcode Command Line Tools, and the macOS SDK:

```sh
git clone https://github.com/meihaowei/NetBar.git
cd NetBar
chmod +x scripts/release.sh
./scripts/release.sh --local
open NetBar.app
```

The local build is universal for Apple Silicon and Intel Macs. It is intended
for development and testing.

## Public release

Public distribution requires an Apple Developer Program membership and a
`Developer ID Application` certificate. Store notarization credentials in the
macOS Keychain once:

```sh
xcrun notarytool store-credentials "netbar-notary" \
  --apple-id "you@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

Then build, sign, notarize, staple, and package:

```sh
DEVELOPER_ID_IDENTITY="Developer ID Application: Your Name (TEAM_ID)" \
NOTARY_PROFILE="netbar-notary" \
./scripts/release.sh --release
```

The release script runs Gatekeeper verification and writes a SHA-256 checksum.

## Privacy

NetBar reads aggregate system counters through public Apple APIs. It does not
inspect packet contents and does not collect, store, or transmit personal data.

## License

MIT. See [LICENSE](LICENSE).
