#!/bin/bash
set -euo pipefail

# Signs a Release archive of the iPhone app (with its widget, Watch app, and Watch
# widget) and uploads it to App Store Connect for TestFlight.
# Secrets enter only through environment variables; never enable shell tracing.
profile_vars=(
  APPLE_PROFILE_APP_BASE64 APPLE_PROFILE_WIDGET_BASE64
  APPLE_PROFILE_WATCH_BASE64 APPLE_PROFILE_WATCH_WIDGET_BASE64
)
required=(
  APPLE_TEAM_ID APPLE_DISTRIBUTION_CERTIFICATE_BASE64 "${profile_vars[@]}"
  APP_STORE_CONNECT_KEY_ID APP_STORE_CONNECT_ISSUER_ID APP_STORE_CONNECT_PRIVATE_KEY
  RUNNER_TEMP GITHUB_RUN_NUMBER GITHUB_RUN_ATTEMPT
)
for name in "${required[@]}"; do
  if [[ -z "${!name:-}" ]]; then
    echo "::error::Missing $name. See ci/README.md for TestFlight setup."
    exit 1
  fi
done
# Empty PKCS#12 passwords are supported, but the variable must be present.
: "${APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD?Set the certificate password (may be empty)}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"
build_number="$GITHUB_RUN_NUMBER.$GITHUB_RUN_ATTEMPT"
version_setting=()
if [[ "${GITHUB_REF:-}" == refs/tags/v* ]]; then
  version="${GITHUB_REF#refs/tags/v}"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+(\.[0-9]+)?$ ]]; then
    echo '::error::Release tags must use vMAJOR.MINOR or vMAJOR.MINOR.PATCH (for example v2.0.1).'
    exit 1
  fi
  version_setting=("MARKETING_VERSION=$version")
fi

umask 077
signing_dir="$(mktemp -d "$RUNNER_TEMP/anyring-signing.XXXXXX")"
keychain="$signing_dir/signing.keychain-db"
installed_profiles=()
original_keychains=()
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line#\"}"
  [[ -n "$line" ]] && original_keychains+=("${line%\"}")
done < <(security list-keychains -d user)
cleanup() {
  if ((${#original_keychains[@]})); then
    security list-keychains -d user -s "${original_keychains[@]}" >/dev/null 2>&1 || true
  fi
  security delete-keychain "$keychain" >/dev/null 2>&1 || true
  if ((${#installed_profiles[@]})); then
    rm -f "${installed_profiles[@]}"
  fi
  rm -rf "$signing_dir"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

printf '%s' "$APPLE_DISTRIBUTION_CERTIFICATE_BASE64" | base64 --decode > "$signing_dir/certificate.p12"
printf '%s' "$APP_STORE_CONNECT_PRIVATE_KEY" > "$signing_dir/AuthKey.p8"
openssl pkey -in "$signing_dir/AuthKey.p8" -noout >/dev/null
profile_plists=()
for name in "${profile_vars[@]}"; do
  printf '%s' "${!name}" | base64 --decode > "$signing_dir/$name.mobileprovision"
  security cms -D -i "$signing_dir/$name.mobileprovision" > "$signing_dir/$name.plist"
  profile_plists+=("$signing_dir/$name.plist")
done
# One "BUNDLE_ID UUID" line per profile; the secrets may be supplied in any order.
profile_map="$(python3 ci/signing_metadata.py "$APPLE_TEAM_ID" "$signing_dir/ExportOptions.plist" "${profile_plists[@]}")"

keychain_password="$(openssl rand -hex 32)"
security create-keychain -p "$keychain_password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$keychain_password" "$keychain"
security import "$signing_dir/certificate.p12" -P "$APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD" \
  -A -t cert -f pkcs12 -k "$keychain"
security set-key-partition-list -S apple-tool:,apple:,codesign: -k "$keychain_password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" ${original_keychains[@]+"${original_keychains[@]}"}
if ! security find-identity -v -p codesigning "$keychain" | grep -q 'Apple Distribution:'; then
  echo '::error::The P12 must contain a valid Apple Distribution certificate and its private key.'
  exit 1
fi

# Each target picks its own profile: the specifier resolves through a setting
# named after the target's bundle ID, e.g. ANYRING_PROFILE_com_potomushto_AnyRing.
profile_settings=()
while read -r bundle_id uuid; do
  profile_settings+=("ANYRING_PROFILE_${bundle_id//[^A-Za-z0-9]/_}=$uuid")
  for name in "${profile_vars[@]}"; do
    if grep -q "$uuid" "$signing_dir/$name.plist"; then
      # Support both provisioning-profile locations used by Xcode versions.
      for profile_dir in \
        "$HOME/Library/MobileDevice/Provisioning Profiles" \
        "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"; do
        mkdir -p "$profile_dir"
        cp "$signing_dir/$name.mobileprovision" "$profile_dir/$uuid.mobileprovision"
        installed_profiles+=("$profile_dir/$uuid.mobileprovision")
      done
    fi
  done
done <<< "$profile_map"

archive_path="$RUNNER_TEMP/AnyRing.xcarchive"
xcodebuild -project AnyRing/AnyRing.xcodeproj -scheme 'AnyRing (iOS)' \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY='Apple Distribution' \
  'PROVISIONING_PROFILE_SPECIFIER=$(ANYRING_PROFILE_$(PRODUCT_BUNDLE_IDENTIFIER:identifier))' \
  "${profile_settings[@]}" \
  CURRENT_PROJECT_VERSION="$build_number" ${version_setting[@]+"${version_setting[@]}"} archive

xcodebuild -exportArchive -archivePath "$archive_path" \
  -exportOptionsPlist "$signing_dir/ExportOptions.plist" \
  -exportPath "$RUNNER_TEMP/anyring-export" \
  -authenticationKeyPath "$signing_dir/AuthKey.p8" \
  -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID" \
  -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf 'Uploaded AnyProgress build **%s** to App Store Connect. It will appear in TestFlight after Apple finishes processing.\n' \
    "$build_number" >> "$GITHUB_STEP_SUMMARY"
fi
