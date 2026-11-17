# Neutral period control — combined release

The local candidate below was subsequently integrated with saved configurations and the compact legend, then uploaded in **AnyProgress 2.0 (41.2)** on **2026-11-17T07:43:05Z**, source `b916eaa7909f1929c6cafe213e419cda669a2ad5`. Full release evidence is in `ci/RELEASE.md`; the following verification record describes the earlier isolated candidate, not the final publication status.

Based on fetched origin/main `7b77fad87a0afda4c362eea628ba1c2820d42515` (release source `34142b2f3bfe42e3ba602cf81f522cc8095ce78d`, AnyProgress 2.0 (37.1)). Not pushed or uploaded.

Only the iOS period selector and week-selection colors/copy change: **Period**, neutral secondary label/chevron, primary value, graphite included dates and gray underline. Native Picker checkmark, 44-point minimum target, full-date/Today accessibility and included/not-included values remain. Accessibility label is Period; value is 3 days (or current selection). Explicit local Menu tint and foreground colors avoid its inherited blue accent; no global tint or ring-palette changes.

No changes to formula/data providers, queries, identifiers, App Groups, Watch/widgets, four-target signing, or calendar-boundary/foreground refresh implementation. Original worktree's 13 dirty files were hash-verified unchanged; released compact worktree remains clean.

## Verification (2026-11-16)

Evidence root: `/Users/tinyserve/.hermes/cache/scratch/anyring-neutral-period/`.

- Release build-for-testing succeeded. Final `final-dark.xcresult`: **5 methods passed**; `final-light.xcresult`: **1 method passed**; no failures/skips/result-bundle runtime warnings. Earlier `green-light.xcresult` also passed both UI methods.
- `testNeutralPeriodLabelAndRenderedColors` runs ordinary and accessibility XXXL sizes in each theme, asserts Period label/current value, target height, zero chromatic pixels in rendered selector/full week row, and changes 3 to 5 days through the real menu. Screenshots inspected, including settled menu checkmark. Native XXXL menu scrolls; not all five options fit simultaneously.
- Existing compact-dashboard UI test passes exact **six additional synthetic reads** for a period change, foreground refresh, 5-day persistence after cold relaunch, and unchanged appearance persistence.
- Two RollingWeek arithmetic tests and hosted SwiftUI midnight/timezone lifecycle test pass. Ordinary minute ticks still make no refresh call. These inject dates/calendars; not an overnight physical-device test.
- Final native screenshot aliases: `dark-standard.png`, `dark-xxxl.png`, `light-standard.png`, `light-xxxl.png`. Final original attachments and manifests: `final-dark-images/`, `final-light-images/`. Checked dark menu: `final-dark-images/D786589A-83F6-4BD4-887A-7FE11E1B9A7E.png`; light XXXL menu: `final-light-images/1CA2F5D6-CFD0-49C6-B5C5-8B4E2755054A.png`.
- `pixel-contrast.json`: sampled actual screenshot RGB, zero pixels with channel spread above 8 in the control/week region in all four captures. Text contrast: dark secondary **6.99:1**, selected **13.58:1**; light secondary **5.74:1**, selected **17.62:1**. Backgrounds dark (28,28,30)/selected (46,46,46), light white/selected (235,235,235). Antialiased edge pixels are not treated as the foreground color.

## Limits and resource release

Synthetic simulator data only, iPhone SE (3rd generation), iOS 27.2, Xcode 27.2; no live HealthKit/device-signing claim, full-suite rerun, VoiceOver spoken traversal, push, upload or release. Native menu retains system translucent material (ring colors can show through); label text/checkmark are neutral.

Initial build was interrupted by tool timeout; fresh-simulator UI startup hit AX initialization timeout. Baseline red run on the existing simulator reproduced the old label/value and blue selector pixels; stopped during a slow second launch. First green run had one foreground telemetry timeout under host load; unmodified foreground test then passed in light and final dark runs. Logs/results retained, not hidden.

Task-created simulator `55BF8BF3-F628-4D10-A799-ABE6E3C4756E` was shut down before switching to the already-booted compact SE, and confirmed Shutdown at **2026-11-16 23:00:39 CET**. Final tests used existing `7AB41532-628A-4CDB-BED5-4CA6024200D8`; restored its original dark appearance. That simulator was not created by this task and was not shut down. All task xcodebuild runs have finished; no other simulator/process was killed. KeineMagie files and simulators untouched.
