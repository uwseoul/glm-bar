#!/usr/bin/env bash
set -euo pipefail

NOTARY_PROFILE_NAME="${NOTARY_PROFILE_NAME:-glmbar-notary}"

# Optional for Apple notarization (skip if not available)
OPTIONAL_NOTARY_VARS=(
    "APPLE_ID"
    "APPLE_APP_SPECIFIC_PASSWORD"
    "APPLE_TEAM_ID"
    "APPLE_DEVELOPER_ID_APPLICATION"
)

# Check if notarization is available
notarization_available=true
for var_name in "${OPTIONAL_NOTARY_VARS[@]}"; do
    if [[ -z "${!var_name:-}" ]]; then
        notarization_available=false
        break
    fi
done

if [[ "$notarization_available" == "true" ]]; then
    echo "[release-prereqs] OK: Apple notarization credentials are present."
    echo "[release-prereqs] Notary keychain profile contract: $NOTARY_PROFILE_NAME"
else
    echo "[release-prereqs] NOTE: Apple notarization credentials not found. Skipping notarization."
    echo "[release-prereqs] Users will see 'unidentified developer' warning on first launch."
fi

echo "[release-prereqs] OK: Ready to build release."
