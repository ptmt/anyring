# CI and TestFlight

The [iOS workflow](../.github/workflows/testflight.yml) runs on GitHub's `xcode-27`
runner with Xcode 27.2; the Swift compiler in Xcode 26.6 crashes on this project.
It uses native `xcodebuild` signing and upload; Fastlane is not required.

| Trigger | Result |
| --- | --- |
| Pull request or push to `main` | Check the signing configuration logic, build for the simulator, and archive Release without signing |
| Actions → iOS → Run workflow on `main` | Run the build checks and tests; select `publish` to sign all four bundles and upload with the version from the Xcode project |

The build number is `<run number>.<run attempt>`. Uploads are serialized and are
never cancelled by a newer upload. The upload job uses the `testflight` GitHub
environment, restricted to `main`; pull requests never receive signing credentials.
No signing files, archives, or debug symbols are uploaded as workflow artifacts.
Build numbers fail closed above 9999 runs or 99 attempts. Marketing version is
changed intentionally in the project, not inferred from tags.

## Signing

The archive contains four signed bundles, and each needs its own **App Store
Connect distribution** provisioning profile with HealthKit and the app group
`group.49PJNAT2WC.com.potomushto.AnyRing`:

| Bundle ID | Target | Secret |
| --- | --- | --- |
| `com.potomushto.AnyRing` | iPhone app | `APPLE_PROFILE_APP_BASE64` |
| `com.potomushto.AnyRing.RingWidget` | iPhone widget | `APPLE_PROFILE_WIDGET_BASE64` |
| `com.potomushto.AnyRing.watchkitapp` | Watch app | `APPLE_PROFILE_WATCH_BASE64` |
| `com.potomushto.AnyRing.watchkitapp.RingWidget` | Watch widget | `APPLE_PROFILE_WATCH_WIDGET_BASE64` |

`ci/signing_metadata.py` checks every profile's team, app ID, type, capabilities,
validity dates, and membership of the exact imported distribution certificate.
It matches profiles to targets by their app ID and rejects non-original teams.
The certificate must have the original team OU and a valid private-key identity.
Each of the four app/extension targets resolves its own profile UUID through
target-scoped CI settings; local signing remains Automatic. Profiles are installed
as private regular files in both Xcode discovery directories with exclusive
creation and durable ownership journals. Cleanup restores the original keychain
list and removes only owned profiles; a trap and `always()` step retry failures.
Replace profiles and certificate secrets together when renewing signing assets.

## GitHub configuration

All values live in the `testflight` environment (Settings → Environments).

| Name | Kind | Value |
| --- | --- | --- |
| `APPLE_TEAM_ID` | Variable | Apple Developer team ID |
| `APPLE_DISTRIBUTION_CERTIFICATE_BASE64` | Secret | Base64 of the Apple Distribution `.p12`, including its private key |
| `APPLE_DISTRIBUTION_CERTIFICATE_PASSWORD` | Secret | Password of the `.p12` |
| `APPLE_PROFILE_*_BASE64` | Secret | Base64 of each `.mobileprovision` from the table above |
| `APP_STORE_CONNECT_KEY_ID` | Secret | App Store Connect team API key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Secret | App Store Connect API issuer ID |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Secret | Entire raw `.p8` file, including BEGIN/END lines; do not base64 this value |

## Release verification

```sh
python3 -m unittest discover -s ci/tests -v
shellcheck ci/*.sh
actionlint -ignore 'label "xcode-27" is unknown' .github/workflows/testflight.yml
gh workflow run testflight.yml -R ptmt/anyring --ref main -f publish=true
```

The narrow actionlint exception accommodates its older runner catalog; actual
GitHub run 43425923970 verified the `xcode-27-arm64` image and Xcode 27.2/27B52.
CI runs the simulator build, unsigned Release archive, and full app/widget/UI
tests before entering the signing environment. `xcodebuild -exportArchive` uses
`destination=upload` and the existing App Store Connect API key. Its real Apple
upload output, not the unsigned validation job or summary text, establishes delivery.
Record run URL, full head SHA, both job IDs, archived version/build, and explicit
upload success. Processing, compliance, tester assignment, and physical Lock
Screen/Watch behavior must be checked separately.

Pre-release discovery found all nine expected environment secret names and
`APPLE_TEAM_ID=49PJNAT2WC`. GitHub does not reveal their values. Local Keychain
only has an Apple Development identity, and the only installed profile belongs
to another app; it is not reused. CI validates the AnyRing secrets in place.
See [release evidence](RELEASE.md) for publication results.
