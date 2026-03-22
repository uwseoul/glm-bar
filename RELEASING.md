# Releasing GLMBar

This runbook covers local and CI release steps for Sparkle-based app updates.

## Scope

- `GLMBar.app` supports Sparkle auto-update.
- `glm-bar` CLI archive is release-only and manual-update.

## Required Secrets

Release pipeline requires:

- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `APPLE_TEAM_ID`
- `APPLE_DEVELOPER_ID_APPLICATION`
- `SPARKLE_PRIVATE_KEY`
- `SPARKLE_PUBLIC_KEY`

## Local Release

1. Validate prerequisites.

```bash
./scripts/check-release-prereqs.sh
```

2. Build, sign, notarize, staple, and generate appcast.

```bash
RELEASE_VERSION=1.0.1 RELEASE_BUILD_NUMBER=101 RELEASE_TAG=v1.0.1 ./scripts/release-macos.sh
```

3. Verify outputs.

- `dist/GLMBar.app`
- `dist/GLMBar.zip`
- `dist/glm-bar-macos.tar.gz`
- `updates/appcast.xml`

4. Confirm appcast enclosure URL points to the exact tag asset.

- `https://github.com/uwseoul/glm-bar/releases/download/v1.0.1/GLMBar.zip`

## CI Release (GitHub Actions)

- Workflow: `.github/workflows/release.yml`
- Trigger: push tag matching `v*`
- Outputs:
  - GitHub Release assets: `dist/GLMBar.zip`, `dist/glm-bar-macos.tar.gz`
  - GitHub Pages artifact from `updates/` including `appcast.xml`

Tag and push:

```bash
git tag v1.0.1
git push origin v1.0.1
```

## Version Rules

- `RELEASE_VERSION` should match the semantic tag without `v`.
- `RELEASE_TAG` should include `v` prefix.
- `RELEASE_BUILD_NUMBER` should be monotonic.

## Recovery Guide

### Missing certificate identity

- Symptom: prereq script fails identity check.
- Action: install the Developer ID certificate into login keychain and retry `./scripts/check-release-prereqs.sh`.

### Notarization rejected

- Symptom: `xcrun notarytool submit ... --wait` fails.
- Action: inspect notarization log, fix signature/runtime entitlement issue, rerun release script.

### Appcast URL mismatch

- Symptom: release script fails enclosure URL check.
- Action: confirm `REPO_SLUG`, `RELEASE_TAG`, and generated appcast contain expected GitHub Releases URL.

### Placeholder Sparkle key left in bundle plist

- Symptom: release verification passes non-empty key but updater trust key is placeholder.
- Action: ensure release process sets `SPARKLE_PUBLIC_KEY` and replaces placeholder before publishing.
