#!/bin/sh
# Strip download quarantine and ad-hoc sign the app so macOS Gatekeeper
# allows local debug builds without an Apple Developer certificate.
set -eu

APP_BUNDLE="${1:?app bundle path required}"
ENTITLEMENTS="${2:-}"

xattr -cr "$APP_BUNDLE" 2>/dev/null || true

for dir in "$APP_BUNDLE/Contents/Frameworks" "$APP_BUNDLE/Contents/MacOS"; do
  if [ ! -d "$dir" ]; then
    continue
  fi
  find "$dir" \( -name '*.framework' -o -name '*.dylib' \) -print0 \
    | sort -rz \
    | while IFS= read -r -d '' item; do
        codesign --force --sign - --timestamp=none "$item" 2>/dev/null || true
      done
done

if [ -n "$ENTITLEMENTS" ] && [ -f "$ENTITLEMENTS" ]; then
  codesign --force --sign - --timestamp=none --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"
else
  codesign --force --sign - --timestamp=none "$APP_BUNDLE"
fi
