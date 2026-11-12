#!/bin/sh
# Builds MTMR 0.28 with this repo's patch (keyboard backlight slider, Control Strip style
# sliders, group icons, dialog watcher) from ~/Repositories/MTMR and installs it.
set -e

DIR="$(cd "$(dirname "$0")" && pwd)"
REPO="${MTMR_REPO:-$HOME/Repositories/MTMR}"

if [ ! -d "$REPO" ]; then
  git clone -q --branch v0.28 https://github.com/Toxblh/MTMR.git "$REPO"
  git -C "$REPO" apply "$DIR/mtmr-keyboard-brightness.patch"
fi

xcodebuild -quiet -project "$REPO/MTMR.xcodeproj" -scheme MTMR -configuration Release \
  -derivedDataPath "$REPO/build" CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= build

APP="$REPO/build/Build/Products/Release/MTMR.app"

# Sign everything ad hoc so dyld accepts Sparkle, before copying: re-signing the installed copy
# makes its first launch fail. Do not sign with an "Apple Development" certificate: macOS
# blocked that build as malware and moved it to the Trash.
codesign --force --deep --sign - --preserve-metadata=entitlements "$APP"

osascript -e 'quit app "MTMR"' || true
rm -rf /Applications/MTMR.app
ditto "$APP" /Applications/MTMR.app

# No update checks (an update would replace this build) and no trackpad gestures (unused, and
# they make MTMR handle every trackpad touch)
defaults write Toxblh.MTMR SUEnableAutomaticChecks -bool false
defaults write Toxblh.MTMR com.toxblh.mtmr.settings.multitouchGestures -bool false

open -a MTMR
