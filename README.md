[한국어 버전 (README_KR.md)](./README_KR.md)

# GLM Bar 🚀

A lightweight and powerful macOS menu bar application to monitor your **Zhipu AI (z.ai) Coding Plan** usage in real-time.

![App UI Sample](https://github.com/uwseoul/glm-bar/raw/main/screenshot_placeholder.png) 
*(UI Example: iStat Menus style 2-row layout)*

## ✨ Key Features

 - **iStat Menus Style UI**: Optimized 2-row vertical layout (Label/Value) for the menu bar.
- **Multi-Quota Monitoring**: Track 5-Hour (5H), Weekly (WK), and Monthly (MO) usage at a glance.
- **Three Display Modes**:
  - **Percent (%)**: Shows usage percentage
  - **Graph (Bar)**: Visual bar graph
  - **Speed (Rate)**: Shows usage speed relative to remaining time (Fast/Normal/Slow)
- **Speed-Based Color Indication**:
  - 🔴 Fast: Rapid usage - risk of exceeding quota
  - 🔵 Normal: Average usage speed
  - 🟢 Slow: Slow usage - safe margin
- **Dark Mode Support**: Auto/Light/Dark theme selection
- **Official Z.ai Logo**: Uses official Zhipu AI branding
- **Automatic App Updates (Sparkle)**: `GLMBar.app` supports in-app update checks and automatic update preference.
- **Privacy Focused**: Your API Key is NOT stored in the source code; it's kept locally and securely on your Mac using `UserDefaults`.
- **Launch at Login**: Option to automatically start the app when you log in.
- **Native Performance**: Built with Swift/SwiftUI for extremely low CPU and memory footprint.

## 🛠 Installation & Usage

### 1. Download App (Recommended) - `.app` Bundle
The easiest way to use the app. Works like any other macOS application.
1. Download `GLMBar.zip` from the [Releases](https://github.com/uwseoul/glm-bar/releases) page.
2. Extract the ZIP and move `GLMBar.app` to your **Applications** folder.
3. Launch the app. (If you see an "Unidentified Developer" warning, right-click the app and select 'Open'.)

### 2. Download Terminal Binary
1. Download `glm-bar-macos.tar.gz` from the Releases page.
2. Extract and run via terminal: `chmod +x glm-bar && ./glm-bar &`

The terminal binary is manual-update only. Automatic updates apply only to `GLMBar.app`.

### 3. Build from Source
If you prefer to build it yourself, run the following in your terminal:

```bash
./scripts/build-universal.sh
```

This creates a **Universal Binary** (works on both Intel and Apple Silicon Macs):
- `dist/glm-bar` - Terminal binary
- `dist/GLMBar.app` - App bundle
- `dist/glm-bar-macos.tar.gz` - Release archive (terminal binary)
- `dist/GLMBar.zip` - Release archive (app bundle)

### 4. Release Preflight Contract (Local + CI)
Before a release build, run:

```bash
./scripts/check-release-prereqs.sh
```

Required environment variables:
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_DEVELOPER_ID_APPLICATION`
- `SPARKLE_PRIVATE_KEY`
- `SPARKLE_PUBLIC_KEY`

Release builds also require explicit version inputs from one source:

```bash
RELEASE_BUILD=1 RELEASE_VERSION=1.2.3 RELEASE_BUILD_NUMBER=123 ./scripts/build-universal.sh
```

Notary profile contract name: `glmbar-notary` (override with `NOTARY_PROFILE_NAME` only if needed).

**Requirements:** macOS 11.0 (Big Sur) or later

To run the terminal binary:
```bash
./dist/glm-bar &
```

To install the app bundle:
```bash
cp -r dist/GLMBar.app /Applications/
```

## 🔄 Automatic Updates (App Only)

`GLMBar.app` uses Sparkle for in-app updates.

- Manual check: open app popup -> `Check for Updates...`
- Automatic behavior: open app popup -> `Settings...` -> toggle `Automatic Updates`
- Feed URL: `https://uwseoul.github.io/glm-bar/appcast.xml`

`glm-bar` CLI binary does not use Sparkle and must be updated manually from Releases.

## ⚙️ How to Setup
1. Click the menu bar icon to open the popup.
2. Click the **Settings...** button at the bottom.
3. Enter your **Z.ai API Key** and select your platform (`z.ai` or `bigmodel.cn`).
4. Toggle your preferred display style and quota visibility.

## 📝 Tech Stack
- **Language**: Swift
- **Framework**: SwiftUI, AppKit (CoreGraphics rendering)
- **Status**: Active Development

## 📄 License
MIT License

---
*Created with ❤️ for GLM Coding Plan users.*
