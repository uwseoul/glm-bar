#!/usr/bin/env bash
set -euo pipefail

NOTARY_PROFILE_NAME="${NOTARY_PROFILE_NAME:-glmbar-notary}"

REQUIRED_VARS=(
    "APPLE_ID"
    "APPLE_APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
    "APPLE_DEVELOPER_ID_APPLICATION"
    "SPARKLE_PRIVATE_KEY"
    "SPARKLE_PUBLIC_KEY"
)

missing_vars=()

for var_name in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        missing_vars+=("$var_name")
    fi
done

if (( ${#missing_vars[@]} > 0 )); then
    echo "[release-prereqs] Missing required environment variables:" >&2
    for var_name in "${missing_vars[@]}"; do
        echo "  - $var_name" >&2
    done
    echo "[release-prereqs] Export all required variables and retry." >&2
    exit 1
fi

identity_value="${APPLE_DEVELOPER_ID_APPLICATION}"
codesign_identities="$(security find-identity -v -p codesigning 2>/dev/null || true)"

if [[ -z "$codesign_identities" ]]; then
    echo "[release-prereqs] Could not read local code signing identities from keychain." >&2
    echo "[release-prereqs] Ensure your signing certificate is installed and keychain access is allowed." >&2
    exit 1
fi

if [[ "$codesign_identities" != *"\"$identity_value\""* ]]; then
    echo "[release-prereqs] APPLE_DEVELOPER_ID_APPLICATION identity not found in keychain:" >&2
    echo "  - Expected match: $identity_value" >&2
    echo "[release-prereqs] Available identities:" >&2
    echo "$codesign_identities" >&2
    exit 1
fi

echo "[release-prereqs] OK: all required release environment variables are present."
echo "[release-prereqs] OK: signing identity found for APPLE_DEVELOPER_ID_APPLICATION."
echo "[release-prereqs] Notary keychain profile contract: $NOTARY_PROFILE_NAME"
