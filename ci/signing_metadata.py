"""Validate the App Store profiles and create xcodebuild's signing inputs.

usage: signing_metadata.py TEAM_ID EXPORT_OPTIONS_OUT PROFILE_PLIST...

Writes the export options plist and prints one `BUNDLE_ID UUID` line per profile.
"""

import datetime
import hashlib
import os
import plistlib
import re
import sys
from pathlib import Path

# Every signed bundle in the archive: iPhone app, its widget, Watch app, its widget.
BUNDLE_IDS = (
    "com.potomushto.AnyRing",
    "com.potomushto.AnyRing.RingWidget",
    "com.potomushto.AnyRing.watchkitapp",
    "com.potomushto.AnyRing.watchkitapp.RingWidget",
)
APP_GROUP = "group.49PJNAT2WC.com.potomushto.AnyRing"


def profile_bundle_id(profile, team_id):
    """Return the bundle ID an App Store profile signs, or raise ValueError."""
    if team_id != "49PJNAT2WC" or profile.get("TeamIdentifier") != [team_id]:
        raise ValueError("Provisioning profile does not match APPLE_TEAM_ID")
    entitlements = profile.get("Entitlements", {})
    app_id = entitlements.get("application-identifier", "")
    bundle_id = next((b for b in BUNDLE_IDS if app_id == f"{team_id}.{b}"), None)
    if bundle_id is None:
        raise ValueError(f"Provisioning profile for {app_id or 'an unknown app'} is not one of {', '.join(BUNDLE_IDS)}")
    if ("ProvisionedDevices" in profile or profile.get("ProvisionsAllDevices")
            or entitlements.get("get-task-allow") is not False
            or entitlements.get("beta-reports-active") is not True):
        raise ValueError(f"{bundle_id}: use an App Store Connect distribution profile, not a development/ad hoc profile")
    expiry = profile.get("ExpirationDate")
    created = profile.get("CreationDate")
    if not isinstance(created, datetime.datetime) or created.replace(tzinfo=datetime.timezone.utc) > datetime.datetime.now(datetime.timezone.utc):
        raise ValueError(f"{bundle_id}: provisioning profile is not yet valid")
    if not isinstance(expiry, datetime.datetime) or expiry.replace(tzinfo=datetime.timezone.utc) <= datetime.datetime.now(datetime.timezone.utc):
        raise ValueError(f"{bundle_id}: provisioning profile has expired or has no expiration date")
    if not entitlements.get("com.apple.developer.healthkit"):
        raise ValueError(f"{bundle_id}: provisioning profile lacks the HealthKit capability")
    if APP_GROUP not in entitlements.get("com.apple.security.application-groups", []):
        raise ValueError(f"{bundle_id}: provisioning profile lacks the app group {APP_GROUP}")
    if not re.fullmatch(r"[0-9A-Fa-f]{8}(?:-[0-9A-Fa-f]{4}){3}-[0-9A-Fa-f]{12}", profile.get("UUID", "")):
        raise ValueError(f"{bundle_id}: provisioning profile UUID is invalid")
    return bundle_id


def validate_certificate_membership(profiles, certificate):
    """Require the exact imported public certificate in every profile."""
    for profile in profiles:
        if certificate not in profile.get("DeveloperCertificates", []):
            raise ValueError("Signing certificate is not a member of every provisioning profile")


def validate_certificate_subject(subject):
    if not re.search(r'(?:^|,)CN=Apple Distribution:[^,]+(?:,|$)', subject) or not re.search(
        r'(?:^|,)OU=49PJNAT2WC(?:,|$)', subject
    ):
        raise ValueError('Certificate must be Apple Distribution for team 49PJNAT2WC')


def export_options(profiles, team_id, destination="upload"):
    """Map each bundle ID to its profile UUID; exactly one profile per bundle is required."""
    uuids = {}
    for profile in profiles:
        bundle_id = profile_bundle_id(profile, team_id)
        if bundle_id in uuids:
            raise ValueError(f"More than one provisioning profile for {bundle_id}")
        uuids[bundle_id] = profile["UUID"]
    missing = [b for b in BUNDLE_IDS if b not in uuids]
    if missing:
        raise ValueError(f"Missing provisioning profile for {', '.join(missing)}")
    if destination not in ("upload", "export"):
        raise ValueError("Destination must be upload or export")
    return {
        "method": "app-store-connect",
        "destination": destination,
        "teamID": team_id,
        "signingStyle": "manual",
        "signingCertificate": "Apple Distribution",
        "provisioningProfiles": uuids,
        "manageAppVersionAndBuildNumber": False,
        "uploadSymbols": True,
    }


if __name__ == "__main__":
    try:
        team_id, output = sys.argv[1], sys.argv[2]
        profiles = [plistlib.loads(Path(path).read_bytes()) for path in sys.argv[3:]]
        options = export_options(profiles, team_id, os.environ.get("TESTFLIGHT_DESTINATION", "upload"))
        certificate = Path(os.environ["SIGNING_CERTIFICATE_DER"]).read_bytes()
        validate_certificate_subject(os.environ["SIGNING_CERTIFICATE_SUBJECT"])
        validate_certificate_membership(profiles, certificate)
        options["signingCertificate"] = hashlib.sha1(certificate).hexdigest().upper()
        Path(output).write_bytes(plistlib.dumps(options))
        for bundle_id, uuid in options["provisioningProfiles"].items():
            print(bundle_id, uuid)
    except (ValueError, IndexError, plistlib.InvalidFileException) as error:
        sys.exit(str(error))
