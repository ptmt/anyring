# CI and TestFlight

The [iOS workflow](../.github/workflows/testflight.yml) runs on GitHub's `macos-26`
runner with Xcode 26.6. It uses native `xcodebuild` signing and upload; Fastlane
is not required.

| Trigger | Result |
| --- | --- |
| Pull request or push to `main` | Check the signing configuration logic, build for the simulator, and archive Release without signing |
| Push a `vMAJOR.MINOR[.PATCH]` tag | Run the build checks, sign a Release archive, and upload it to App Store Connect for TestFlight. The tag sets the app version |
| Actions → iOS → Run workflow | Run the build checks; select `publish` to also upload with the version from the Xcode project |

The build number is `<run number>.<run attempt>`. Uploads are serialized and are
never cancelled by a newer upload. The upload job uses the `testflight` GitHub
environment; pull requests never receive signing credentials. Debug symbols are
kept as workflow artifacts for 30 days.

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
and expiry, and matches profiles to targets by their app ID. The profiles expire
with the distribution certificate; replace the secrets when you renew it.

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

## Dry run

To sign and package on a Mac without uploading, export the same variables,
set `RUNNER_TEMP`, `GITHUB_RUN_NUMBER`, and `GITHUB_RUN_ATTEMPT`, and run
`TESTFLIGHT_DESTINATION=export bash ci/testflight.sh`. The `.ipa` is written to
`$RUNNER_TEMP/anyring-export`.
