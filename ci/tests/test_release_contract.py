"""Release invariants, using tracked source files and synthetic metadata."""
import plistlib
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'ci'))
import signing_metadata as sm


class ReleaseContractTests(unittest.TestCase):
    def test_certificate_subject_matches_original_team_and_distribution(self):
        sm.validate_certificate_subject('subject= UID=49PJNAT2WC,CN=Apple Distribution: Test,OU=49PJNAT2WC,O=Test,C=DE')
        for subject in ['CN=Apple Development: Test,OU=49PJNAT2WC',
                        'CN=Apple Distribution: Test,OU=OTHERTEAM1']:
            with self.assertRaises(ValueError):
                sm.validate_certificate_subject(subject)

    def test_all_healthkit_bundles_have_both_purpose_strings(self):
        for relative in ['iOS/Info.plist', 'AnyRingWatch/Info.plist', 'RingWidget/Info.plist']:
            with self.subTest(plist=relative):
                info = plistlib.loads((ROOT / 'AnyRing' / relative).read_bytes())
                for key in ['NSHealthShareUsageDescription', 'NSHealthUpdateUsageDescription']:
                    self.assertTrue(info.get(key), f'{relative} requires {key}')

    def test_ipad_orientation_and_encryption_metadata(self):
        info = plistlib.loads((ROOT / 'AnyRing/iOS/Info.plist').read_bytes())
        self.assertEqual(set(info['UISupportedInterfaceOrientations~ipad']), {
            'UIInterfaceOrientationPortrait', 'UIInterfaceOrientationPortraitUpsideDown',
            'UIInterfaceOrientationLandscapeLeft', 'UIInterfaceOrientationLandscapeRight'})
        self.assertIs(info['ITSAppUsesNonExemptEncryption'], False)

    def test_original_entitlements_and_target_scoped_signing(self):
        for path in ['AnyRing.entitlements', 'RingWidgetExtension.entitlements',
                     'AnyRingWatch/AnyRingWatch.entitlements']:
            ent = plistlib.loads((ROOT / 'AnyRing' / path).read_bytes())
            self.assertIs(ent['com.apple.developer.healthkit'], True)
            self.assertEqual(ent['com.apple.security.application-groups'], [sm.APP_GROUP])
        project = (ROOT / 'AnyRing/AnyRing.xcodeproj/project.pbxproj').read_text()
        for bundle in sm.BUNDLE_IDS:
            self.assertIn('PROVISIONING_PROFILE = "$(ANYRING_PROFILE_' + bundle.replace('.', '_') + ')";', project)
        script = (ROOT / 'ci/testflight.sh').read_text()
        self.assertNotIn(' CODE_SIGN_STYLE=Manual', script)
        self.assertNotIn(' CODE_SIGN_IDENTITY=', script)
        self.assertNotIn('allowProvisioningUpdates', script)

    def test_release_is_main_only_and_has_retryable_cleanup(self):
        workflow = (ROOT / '.github/workflows/testflight.yml').read_text()
        self.assertIn("github.ref == 'refs/heads/main'", workflow)
        self.assertIn('if: always()', workflow)
        self.assertIn('bash ci/cleanup.sh', workflow)
        self.assertNotIn('upload-artifact', workflow)
