#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/NetBar.app"
SOURCE="$ROOT/NetBar.swift"
INFO="$ROOT/Info.plist"
BUILD="$ROOT/../work/release"
MODE="${1:-}"

die() {
    print -u2 -- "error: $*"
    exit 1
}

[[ "$MODE" == "--local" || "$MODE" == "--release" ]] || \
    die "usage: $0 --local | --release"

[[ "$APP" == "$ROOT/NetBar.app" ]] || die "unexpected app path"
xcrun --find swiftc >/dev/null

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO")"
IDENTITY="${DEVELOPER_ID_IDENTITY:-}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"

if [[ "$MODE" == "--release" ]]; then
    [[ -n "$IDENTITY" ]] || die "set DEVELOPER_ID_IDENTITY to a Developer ID Application certificate"
    [[ -n "$NOTARY_PROFILE" ]] || die "set NOTARY_PROFILE to a notarytool keychain profile"
fi

rm -rf "$BUILD" "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$BUILD"

xcrun swiftc \
    -O -whole-module-optimization -parse-as-library \
    -target arm64-apple-macosx12.0 \
    "$SOURCE" -o "$BUILD/NetBar-arm64" -framework AppKit

xcrun swiftc \
    -O -whole-module-optimization -parse-as-library \
    -target x86_64-apple-macosx12.0 \
    "$SOURCE" -o "$BUILD/NetBar-x86_64" -framework AppKit

lipo -create "$BUILD/NetBar-arm64" "$BUILD/NetBar-x86_64" \
    -output "$APP/Contents/MacOS/NetBar"
strip -x "$APP/Contents/MacOS/NetBar"
cp "$INFO" "$APP/Contents/Info.plist"

xcrun swiftc -O "$ROOT/scripts/make_icon.swift" \
    -o "$BUILD/make-icon" -framework AppKit
"$BUILD/make-icon" "$BUILD/NetBar.iconset"
find "$BUILD/NetBar.iconset" -type f -name '*.png' -print0 | \
    xargs -0 -n1 sh -c \
    'file="$1"; xcrun pngcrush -brute -reduce -q "$file" "$file.opt"; mv "$file.opt" "$file"' sh
iconutil -c icns "$BUILD/NetBar.iconset" \
    -o "$APP/Contents/Resources/NetBar.icns"

if [[ "$MODE" == "--local" ]]; then
    codesign --force --options runtime --sign - "$APP"
    PACKAGE="$ROOT/NetBar-$VERSION-local.zip"
    rm -f "$PACKAGE"
    ditto -c -k --sequesterRsrc --keepParent "$APP" "$PACKAGE"
    print -- "Local build: $APP"
    print -- "Local archive: $PACKAGE"
    print -- "This archive is ad-hoc signed and must not be used as a public release."
    exit 0
fi

codesign --force --options runtime --timestamp \
    --sign "$IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

ARCHIVE="$BUILD/NetBar-notarization.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ARCHIVE"
xcrun notarytool submit "$ARCHIVE" \
    --keychain-profile "$NOTARY_PROFILE" --wait
xcrun stapler staple "$APP"
xcrun stapler validate "$APP"
spctl --assess --type execute --verbose=4 "$APP"

PACKAGE="$ROOT/NetBar-$VERSION.zip"
rm -f "$PACKAGE"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$PACKAGE"
shasum -a 256 "$PACKAGE" > "$PACKAGE.sha256"

print -- "Release package: $PACKAGE"
print -- "Checksum: $PACKAGE.sha256"
