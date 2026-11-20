# NetBar

A tiny native macOS menu bar monitor for network throughput, CPU usage, and
memory usage. NetBar uses Apple system APIs and has no third-party
dependencies, analytics, or network requests.

## Display

The menu bar title follows this order:

```text
↑ upload rate    CPU%
↓ download rate  memory%
```

Upload is always shown on the top line and download on the bottom line. Click
the title to view exact values. The menu also contains the quit command.
Statistics refresh once per second.

## Requirements

- macOS 12 or later
- Apple Silicon or Intel Mac

The source is compatible with Swift 6 and is built with AppKit.

## Local build

From this directory:

```sh
chmod +x scripts/release.sh
./scripts/release.sh --local
```

This creates a universal, ad-hoc signed app and a local ZIP. Ad-hoc builds are
only suitable for local testing. Do not distribute them publicly.

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
Before publishing, confirm that the app name and bundle identifier do not
conflict with an existing product.

## Privacy

NetBar reads aggregate system counters through public Apple APIs. It does not
inspect packet contents and does not collect, store, or transmit personal data.

## License

MIT. See [LICENSE](LICENSE).
