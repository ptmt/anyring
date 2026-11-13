import datetime
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import signing_metadata as sm

TEAM = "49PJNAT2WC"


def profile(bundle_id, index=0, **overrides):
    value = {
        "TeamIdentifier": [TEAM],
        "UUID": f"00000000-0000-0000-0000-{index:012d}",
        "ExpirationDate": datetime.datetime.now() + datetime.timedelta(days=30),
        "Entitlements": {
            "application-identifier": f"{TEAM}.{bundle_id}",
            "com.apple.developer.healthkit": True,
            "com.apple.security.application-groups": [sm.APP_GROUP],
        },
    }
    value.update(overrides)
    return value


def all_profiles():
    return [profile(bundle_id, index) for index, bundle_id in enumerate(sm.BUNDLE_IDS)]


class SigningMetadataTests(unittest.TestCase):
    def test_maps_every_bundle_to_its_profile(self):
        options = sm.export_options(all_profiles(), TEAM)
        self.assertEqual(set(options["provisioningProfiles"]), set(sm.BUNDLE_IDS))
        self.assertEqual(options["provisioningProfiles"]["com.potomushto.AnyRing.watchkitapp"],
                         "00000000-0000-0000-0000-000000000002")
        self.assertEqual(options["destination"], "upload")
        self.assertEqual(options["signingStyle"], "manual")

    def test_bundle_ids_match_the_xcode_project(self):
        project = (Path(__file__).resolve().parents[2] / "AnyRing/AnyRing.xcodeproj/project.pbxproj").read_text()
        for bundle_id in sm.BUNDLE_IDS:
            self.assertIn(f"PRODUCT_BUNDLE_IDENTIFIER = {bundle_id};", project)

    def assert_rejected(self, profiles, message, team=TEAM):
        with self.assertRaisesRegex(ValueError, message):
            sm.export_options(profiles, team)

    def test_rejects_missing_and_duplicate_profiles(self):
        self.assert_rejected(all_profiles()[:3], "Missing provisioning profile for com.potomushto.AnyRing.watchkitapp.RingWidget")
        self.assert_rejected(all_profiles() + [profile(sm.BUNDLE_IDS[0], 9)], "More than one")

    def test_rejects_wrong_team_app_and_profile_type(self):
        self.assert_rejected(all_profiles(), "APPLE_TEAM_ID", team="OTHERTEAM1")
        self.assert_rejected([profile("com.example.other")], "is not one of")
        self.assert_rejected([profile(sm.BUNDLE_IDS[0], ProvisionedDevices=["udid"])], "distribution profile")

    def test_rejects_expired_profile_and_missing_capabilities(self):
        expired = profile(sm.BUNDLE_IDS[0], ExpirationDate=datetime.datetime(2020, 1, 1))
        self.assert_rejected([expired], "expired")
        no_group = profile(sm.BUNDLE_IDS[3])
        no_group["Entitlements"]["com.apple.security.application-groups"] = []
        self.assert_rejected([no_group], "app group")
        no_health = profile(sm.BUNDLE_IDS[1])
        del no_health["Entitlements"]["com.apple.developer.healthkit"]
        self.assert_rejected([no_health], "HealthKit")


if __name__ == "__main__":
    unittest.main()
