#!/usr/bin/env bash
# Build universal macOS binary (arm64 + x86_64) for GLM Bar
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCE_FILES=(
    "$PROJECT_ROOT/Storage.swift"
    "$PROJECT_ROOT/UsageFetcher.swift"
    "$PROJECT_ROOT/GLMBarApp.swift"
)

if [[ -f "$PROJECT_ROOT/UpdaterController.swift" ]]; then
    SOURCE_FILES+=("$PROJECT_ROOT/UpdaterController.swift")
fi

BUILD_DIR="$PROJECT_ROOT/build"
DIST_DIR="$PROJECT_ROOT/dist"
APP_NAME="GLMBar"
BINARY_NAME="glm-bar"
DEPLOYMENT_TARGET="11.0"
RELEASE_BUILD_FLAG="${RELEASE_BUILD:-0}"
RELEASE_VERSION_INPUT="${RELEASE_VERSION:-}"
RELEASE_BUILD_NUMBER_INPUT="${RELEASE_BUILD_NUMBER:-}"
SPARKLE_FRAMEWORK_SOURCE="$PROJECT_ROOT/vendor/Sparkle.xcframework/macos-arm64_x86_64/Sparkle.framework"
SPARKLE_FRAMEWORK_SEARCH_PATH="$PROJECT_ROOT/vendor/Sparkle.xcframework/macos-arm64_x86_64"
APP_ICON_SOURCE="$PROJECT_ROOT/packaging/icons/AppIcon.icns"

APP_VERSION=""
APP_BUILD_NUMBER=""

resolve_version_inputs() {
    local plist_path="$PROJECT_ROOT/packaging/Info.plist"
    local default_version=""
    local default_build_number=""

    if [[ "$RELEASE_BUILD_FLAG" == "1" ]]; then
        "$SCRIPT_DIR/check-release-prereqs.sh"

        if [[ -z "$RELEASE_VERSION_INPUT" ]]; then
            echo "Release build requires RELEASE_VERSION (for example 1.2.3)." >&2
            exit 1
        fi

        if [[ -z "$RELEASE_BUILD_NUMBER_INPUT" ]]; then
            echo "Release build requires RELEASE_BUILD_NUMBER (for example 123)." >&2
            exit 1
        fi
    fi

    default_version="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$plist_path" 2>/dev/null || true)"
    default_build_number="$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$plist_path" 2>/dev/null || true)"

    APP_VERSION="${RELEASE_VERSION_INPUT:-$default_version}"
    APP_BUILD_NUMBER="${RELEASE_BUILD_NUMBER_INPUT:-$default_build_number}"

    if [[ -z "$APP_VERSION" ]] || [[ -z "$APP_BUILD_NUMBER" ]]; then
        echo "Could not resolve app version/build inputs from release env or packaging/Info.plist." >&2
        exit 1
    fi
}

assert_bundle_assets() {
    if [[ ! -d "$SPARKLE_FRAMEWORK_SOURCE" ]]; then
        echo "Missing Sparkle framework at: $SPARKLE_FRAMEWORK_SOURCE" >&2
        echo "Ensure vendored Sparkle dependency exists before building." >&2
        exit 1
    fi

    if [[ ! -f "$APP_ICON_SOURCE" ]]; then
        echo "Missing app icon at: $APP_ICON_SOURCE" >&2
        exit 1
    fi
}

build_arm64() {
    echo "Building for arm64..."
    mkdir -p "$BUILD_DIR/arm64"
    swiftc \
        -target "arm64-apple-macosx$DEPLOYMENT_TARGET" \
        -O \
        -o "$BUILD_DIR/arm64/$BINARY_NAME" \
        "${SOURCE_FILES[@]}" \
        -F "$SPARKLE_FRAMEWORK_SEARCH_PATH" \
        -framework SwiftUI \
        -framework AppKit \
        -framework Sparkle \
        -Xlinker -rpath \
        -Xlinker "@executable_path/../Frameworks"
    echo "✓ arm64 build complete"
}

build_x86_64() {
    echo "Building for x86_64..."
    mkdir -p "$BUILD_DIR/x86_64"
    swiftc \
        -target "x86_64-apple-macosx$DEPLOYMENT_TARGET" \
        -O \
        -o "$BUILD_DIR/x86_64/$BINARY_NAME" \
        "${SOURCE_FILES[@]}" \
        -F "$SPARKLE_FRAMEWORK_SEARCH_PATH" \
        -framework SwiftUI \
        -framework AppKit \
        -framework Sparkle \
        -Xlinker -rpath \
        -Xlinker "@executable_path/../Frameworks"
    echo "✓ x86_64 build complete"
}

create_universal_binary() {
    echo "Creating universal binary..."
    mkdir -p "$DIST_DIR"
    lipo -create \
        "$BUILD_DIR/arm64/$BINARY_NAME" \
        "$BUILD_DIR/x86_64/$BINARY_NAME" \
        -output "$DIST_DIR/$BINARY_NAME"
    echo "✓ Universal binary created: $DIST_DIR/$BINARY_NAME"
}

create_app_bundle() {
    echo "Creating app bundle..."
    local app_dir="$DIST_DIR/$APP_NAME.app"
    local contents_dir="$app_dir/Contents"
    local macos_dir="$contents_dir/MacOS"
    local frameworks_dir="$contents_dir/Frameworks"
    local resources_dir="$contents_dir/Resources"
    
    rm -rf "$app_dir"
    mkdir -p "$macos_dir" "$frameworks_dir" "$resources_dir"
    
    cp "$DIST_DIR/$BINARY_NAME" "$macos_dir/$APP_NAME"
    cp "$PROJECT_ROOT/packaging/Info.plist" "$contents_dir/Info.plist"
    cp "$APP_ICON_SOURCE" "$resources_dir/AppIcon.icns"
    cp -R "$SPARKLE_FRAMEWORK_SOURCE" "$frameworks_dir/"

    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $APP_VERSION" "$contents_dir/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $APP_BUILD_NUMBER" "$contents_dir/Info.plist"

    if [[ -n "${SPARKLE_PUBLIC_KEY:-}" ]]; then
        /usr/libexec/PlistBuddy -c "Set :SUPublicEDKey $SPARKLE_PUBLIC_KEY" "$contents_dir/Info.plist"
    fi
    
    chmod +x "$macos_dir/$APP_NAME"

    sign_app_bundle "$app_dir"
    
    echo "✓ App bundle created: $app_dir"
}

sign_app_bundle() {
    local app_dir="$1"
    local sparkle_framework="$app_dir/Contents/Frameworks/Sparkle.framework"
    local sparkle_current_dir="$sparkle_framework/Versions/Current"
    local signing_identity="-"
    local -a codesign_args=(--force --sign "$signing_identity")

    if [[ "$RELEASE_BUILD_FLAG" == "1" ]]; then
        signing_identity="${APPLE_DEVELOPER_ID_APPLICATION}"
        codesign_args=(--force --sign "$signing_identity" --options runtime --timestamp)
    fi

    if [[ ! -d "$sparkle_framework" ]]; then
        echo "Embedded Sparkle framework missing: $sparkle_framework" >&2
        exit 1
    fi

    if [[ -d "$sparkle_current_dir/XPCServices" ]]; then
        for xpc_service in "$sparkle_current_dir"/XPCServices/*.xpc; do
            [[ -e "$xpc_service" ]] || continue
            codesign "${codesign_args[@]}" "$xpc_service"
        done
    fi

    if [[ -d "$sparkle_current_dir/Autoupdate.app" ]]; then
        codesign "${codesign_args[@]}" "$sparkle_current_dir/Autoupdate.app"
    fi

    codesign "${codesign_args[@]}" "$sparkle_framework"
    codesign "${codesign_args[@]}" "$app_dir"
}

create_release_archives() {
    echo "Creating release archives..."
    
    tar -czf "$DIST_DIR/glm-bar-macos.tar.gz" -C "$DIST_DIR" "$BINARY_NAME"
    echo "✓ Created: $DIST_DIR/glm-bar-macos.tar.gz"
    
    pushd "$DIST_DIR" >/dev/null
    zip -r -q "$APP_NAME.zip" "$APP_NAME.app"
    popd >/dev/null
    echo "✓ Created: $DIST_DIR/$APP_NAME.zip"
}

print_summary() {
    echo ""
    echo "========================================"
    echo "Build Summary"
    echo "========================================"
    echo "Universal binary: $DIST_DIR/$BINARY_NAME"
    lipo -info "$DIST_DIR/$BINARY_NAME"
    echo ""
    echo "App bundle:       $DIST_DIR/$APP_NAME.app"
    echo "App version:      $APP_VERSION"
    echo "App build:        $APP_BUILD_NUMBER"
    echo "Release archives:"
    echo "  - $DIST_DIR/glm-bar-macos.tar.gz"
    echo "  - $DIST_DIR/$APP_NAME.zip"
    echo ""
    file "$DIST_DIR/$BINARY_NAME"
}

main() {
    echo "GLM Bar Universal Build"
    echo "======================="
    echo ""
    
    resolve_version_inputs
    assert_bundle_assets

    build_arm64
    build_x86_64
    create_universal_binary
    create_app_bundle
    create_release_archives
    print_summary
    
    echo ""
    echo "Running verification..."
    "$SCRIPT_DIR/verify-build.sh"
}

main "$@"
