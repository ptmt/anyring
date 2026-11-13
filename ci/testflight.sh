#!/bin/bash
set -euo pipefail
set +x
if [[ "${GITHUB_ACTIONS:-}" != true || "${GITHUB_REF:-}" != refs/heads/main ]]; then
  echo '::error::Publication is restricted to GitHub Actions on main.'
  exit 1
fi

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
if [[ ! "$build_number" =~ ^[1-9][0-9]{0,3}\.[1-9][0-9]?$ ]]; then
  echo '::error::Build number exceeds Apple component limits.'
  exit 1
fi
printf 'Release build number: %s\n' "$build_number"


umask 077
signing_dir="$(mktemp -d "$RUNNER_TEMP/anyring-signing.XXXXXX")"
touch "$signing_dir/owned-by-testflight"
printf 'ANYRING_SIGNING_DIR=%s\n' "$signing_dir" >> "$GITHUB_ENV"
keychain="$signing_dir/signing.keychain-db"
original_keychains=()
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line#\"}"
  [[ -n "$line" ]] && original_keychains+=("${line%\"}")
done < <(security list-keychains -d user)
printf '%s\n' "${original_keychains[@]}" > "$signing_dir/keychains-before"
cleanup() {
  bash "$repo_root/ci/cleanup.sh" "$signing_dir"
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
keychain_password="$(openssl rand -hex 32)"
printf '::add-mask::%s\n' "$keychain_password"
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
security find-certificate -c 'Apple Distribution' -p "$keychain" > "$signing_dir/certificate.pem"
openssl x509 -in "$signing_dir/certificate.pem" -checkend 0 -noout >/dev/null
openssl x509 -in "$signing_dir/certificate.pem" -outform DER -out "$signing_dir/certificate.der"
export SIGNING_CERTIFICATE_DER="$signing_dir/certificate.der"
SIGNING_CERTIFICATE_SUBJECT="$(openssl x509 -in "$signing_dir/certificate.pem" -noout -subject -nameopt RFC2253)"
export SIGNING_CERTIFICATE_SUBJECT
# Validate capabilities, dates, exact IDs, and imported certificate membership.
profile_map="$(python3 ci/signing_metadata.py "$APPLE_TEAM_ID" "$signing_dir/ExportOptions.plist" "${profile_plists[@]}")"
certificate_sha="$(python3 -c 'import plistlib,sys; print(plistlib.load(open(sys.argv[1], "rb"))["signingCertificate"])' "$signing_dir/ExportOptions.plist")"
if ! security find-identity -v -p codesigning "$keychain" | grep -q "$certificate_sha"; then
  echo '::error::Validated certificate has no valid signing private key.'
  exit 1
fi
printf 'Validated all four profiles: original team/bundles, HealthKit, App Group, dates, and certificate membership.\n'

# Each target picks its own profile: the specifier resolves through a setting
# named after the target's bundle ID, e.g. ANYRING_PROFILE_com_potomushto_AnyRing.
profile_settings=()
while read -r bundle_id uuid; do
  profile_settings+=("ANYRING_PROFILE_${bundle_id//[^A-Za-z0-9]/_}=$uuid")
  for name in "${profile_vars[@]}"; do
    if grep -q "$uuid" "$signing_dir/$name.plist"; then
      profile_root="$signing_dir/profile-$uuid"
      mkdir "$profile_root"
      printf '%s' "$uuid" > "$profile_root/profile-uuid"
      cp "$signing_dir/$name.mobileprovision" "$profile_root/profile.mobileprovision"
      python3 ci/profile_install.py install "$profile_root"
    fi
  done
done <<< "$profile_map"

archive_path="$signing_dir/AnyRing.xcarchive"
xcodebuild -project AnyRing/AnyRing.xcodeproj -scheme 'AnyRing (iOS)' \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  ANYRING_CI_SIGN_STYLE=Manual ANYRING_CI_IDENTITY="$certificate_sha" \
  "${profile_settings[@]}" \
  CURRENT_PROJECT_VERSION="$build_number" archive

xcodebuild -exportArchive -archivePath "$archive_path" \
  -exportOptionsPlist "$signing_dir/ExportOptions.plist" \
  -exportPath "$signing_dir/export" \
  -authenticationKeyPath "$signing_dir/AuthKey.p8" \
  -authenticationKeyID "$APP_STORE_CONNECT_KEY_ID" \
  -authenticationKeyIssuerID "$APP_STORE_CONNECT_ISSUER_ID"

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  printf 'Uploaded AnyProgress build **%s** to App Store Connect. It will appear in TestFlight after Apple finishes processing.\n' \
    "$build_number" >> "$GITHUB_STEP_SUMMARY"
fi
