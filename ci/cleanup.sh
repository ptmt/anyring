#!/bin/bash
# Retryable cleanup for the signing trap and workflow always() step.
set +x
set -euo pipefail
root="${1:-}"
[[ -n "$root" && -d "$root" ]] || exit 0
[[ "$(basename "$root")" == anyring-signing.* && -f "$root/owned-by-testflight" ]] || exit 1
status=0
if [[ -f "$root/keychains-before" ]]; then
  keychains=()
  while IFS= read -r path; do keychains+=("$path"); done < "$root/keychains-before"
  security list-keychains -d user -s "${keychains[@]}" || status=1
fi
if [[ -f "$root/signing.keychain-db" ]]; then
  security delete-keychain "$root/signing.keychain-db" || status=1
fi
shopt -s nullglob
for journal in "$root/profile-install.json" "$root"/profile-*/profile-install.json; do
  [[ -f "$journal" ]] || continue
  python3 "$(dirname "$0")/profile_install.py" cleanup "$(dirname "$journal")" || status=1
done
if [[ "$status" == 0 ]]; then
  rm -rf -- "$root"
else
  # Retain only nonsecret ownership journals and any undeletable keychain.
  python3 - "$root" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
keep = {'owned-by-testflight', 'keychains-before', 'profile-install.json', 'signing.keychain-db'}
for path in root.rglob('*'):
    if path.is_file() and path.name not in keep:
        path.unlink()
PY
fi
exit "$status"
