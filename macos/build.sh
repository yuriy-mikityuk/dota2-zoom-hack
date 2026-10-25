#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
output_dir="${1:-$project_dir/build}"
mkdir -p "$output_dir"
output_dir="$(cd "$output_dir" && pwd)"
# Sign outside synced folders: File Provider can re-add FinderInfo while signing.
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/dota-training-zoom.XXXXXX")"
app="$staging_dir/Dota Training Zoom.app"
mkdir -p "$app/Contents/MacOS"
xcrun swiftc -O -swift-version 5 -target arm64-apple-macosx13.0 \
    "$project_dir/TrainingConfig.swift" "$project_dir/TrainingZoom.swift" \
    -o "$output_dir/TrainingZoom-arm64" -framework AppKit
xcrun swiftc -O -swift-version 5 -target x86_64-apple-macosx13.0 \
    "$project_dir/TrainingConfig.swift" "$project_dir/TrainingZoom.swift" \
    -o "$output_dir/TrainingZoom-x86_64" -framework AppKit
xcrun lipo -create "$output_dir/TrainingZoom-arm64" "$output_dir/TrainingZoom-x86_64" \
    -output "$app/Contents/MacOS/TrainingZoom"
cp "$project_dir/Info.plist" "$app/Contents/Info.plist"
xattr -cr "$app"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
ditto -c -k --norsrc --noextattr --keepParent "$app" "$output_dir/Dota Training Zoom.zip"
printf 'App: %s\nArchive: %s\n' "$app" "$output_dir/Dota Training Zoom.zip"
