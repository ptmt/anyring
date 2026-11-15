# Workout-only heart-rate zone minutes

## Scope and base

Implemented and independently reviewed in `/Users/tinyserve/Projects/anyring-workout-zones`, branch `feat/workout-zone-metrics`, from freshly fetched `origin/main` at `f9ff0bd53b0984b28ee3cd168b643082dfbeb024` (includes `d33b3e8`). Release publication uses the existing main-only explicit TestFlight workflow; exact source/run/build evidence is recorded in `ci/RELEASE.md`. The original dirty worktree is not edited. Existing custom names, calendar-day period semantics, native refresh, dark concentric artwork, endpoint rendering and personal metric configuration are preserved.

Two selections under Workouts:

- Heart rate zones 2–3 (`combinedZones2And3`)
- Heart rate zones 4–5 (`combinedZones4And5`)

Both are sums of workout zone seconds / 60, in `min`, higher-is-better. A 30-minute editable placeholder goal is not a medical/training recommendation. The shared main period is today plus the previous N−1 calendar days through now, in the current calendar/timezone. No change to the existing heart-rate aggregation or user goal/start values.

## Verified Apple API and availability

Authoritative references inspected:

- https://developer.apple.com/documentation/healthkit/accessing-workout-zone-data
- https://developer.apple.com/documentation/healthkit/hkworkoutzone/index
- https://developer.apple.com/videos/play/wwdc2026/207/

Installed Xcode 27.2 (27B52), iPhoneOS 27.2 SDK, `HealthKit.swiftinterface` declares `HKWorkout.zoneGroupsByType`, `HKWorkoutZoneGroup`, `HKWorkoutZoneDuration`, and `HKWorkoutZoneConfiguration` as OS **27.0+**, not 26.0. Watch Release compilation also verifies the watchOS SDK API. Deployment minimum remains 26.0. All access is guarded with `#available(iOS 27.0, watchOS 27.0, macOS 27.0, *)`; earlier OS versions return a compact unavailable error.

The actual access is `workout.zoneGroupsByType?[HKQuantityType(.heartRate)]`, then `group.configuration.zones` and `group.zoneDurations` (`duration` is TimeInterval seconds). Apple's `zone.index` is **zero-based**, ordered low to high. Thus human zones 2–3 are indices 1,2 and 4–5 are indices 3,4. A deterministic test constructs an actual SDK `HKWorkoutZoneConfiguration` and confirms indices 0...4. Threshold numbers in that test are synthetic only and never used to classify production heart rates.

Only workouts and heart rate are requested/observed for these metrics. Cycling power is not requested. Read authorization cannot be inferred from requestAuthorization success: HealthKit intentionally does not distinguish denied read access from absent data.

## Source architecture and persistence

`HealthKitDataSource.fetchWorkouts` is the new async source seam, using the native cancellable `HKSampleQueryDescriptor` over `.workout(predicate)` in DeviceHealthKitDataSource. `WorkoutZoneRecord` is a Sendable, synthetic-testable value boundary. The dedicated `HealthKitWorkoutProvider` reuses existing provider configuration, snapshot, RingViewModel generation/cancellation and cache machinery rather than rewriting providers. Active ring editors can change metric without replacing the view model; provider dispatch uses immutable requested configuration.

An optional strongly typed `workoutMetric` field extends Config.v3. Missing fields preserve all old quantity configurations; unknown enum values fail decoding rather than silently selecting another source. Appearance, custom names, goal and global period round-trip through existing persistence and Watch configuration snapshots. Source identity participates in exact reading/cache equality. Metadata-only rename preserves the reading date, model identity and read count. Old builds ignore the new field but see a heart-rate Sum compatibility payload; their existing discrete/cumulative validation returns unsupported aggregation instead of presenting heart-rate averages as minutes. This is graceful unavailability, not functional backward support for workout zones.

No new persistent raw Health cache or shared mutable query task is introduced. Each caller owns its native async query; concurrent rings/snapshot callers are independent, not coalesced. Cancellation is checked before and after awaiting; existing generation fences reject late completions. Only aggregate ring snapshots use the existing configuration-matched widget cache.

## Conservative coverage policy / first-release limits

This release intentionally fails closed rather than estimating incomplete totals:

- Only **parent HKWorkout aggregates** are read. Never add HKWorkoutActivity totals to parent totals. Activity-only stored zones without a parent aggregate are unsupported.
- Only complete, five-zone configurations with zero-based indices 0...4 and explicit finite nonnegative duration entries for all five zones are accepted. Custom five-zone workout configurations are respected as stored; no recomputation from today's preferred configuration, max-HR percentages or mean HR. A different zone count is unsupported.
- Stored HealthKit zone aggregates are authoritative recorded durations; they need not fill the entire active workout duration. Independent review reproduced a false rejection of a valid 330-second aggregate in a 600-second active/900-second elapsed workout (RED), then removed the invented full-coverage equality (GREEN). There is no raw-sample maximum-gap heuristic or interpolation. Partial recorded coverage is reported as recorded zone minutes, not claimed as complete sampling.
- Stored durations are used without subtracting pauses again or filling gaps. Finite nonnegative entries and a positive total are required; only totals exceeding elapsed workout time (one-second rounding tolerance), invalid dates and duplicate zone entries are rejected. Actual pause behavior across recording apps still requires physical acceptance; no claim beyond the API-provided aggregate is made.
- Query has no strict-start restriction, so overlapping period boundaries are discovered. Whole-workout aggregates cannot be temporally clipped: any relevant workout crossing the period start or end causes incomplete coverage, not proportional allocation. No sample-timeline fallback is implemented.
- Duplicate parent UUIDs are deterministically deduplicated after start/UUID sorting. Distinct overlapping workouts, including multiple-device recordings, **defer the entire total as incomplete**. No arbitrary device wins, overlapping aggregate is added, or fractional subtraction is invented. Adjacent nonoverlapping workouts sum normally. A timeline-aware merge for distinct overlapping records is explicitly deferred.
- A period with no readable workouts, missing zones, imported workouts lacking valid parent zones, denied data or absent heart rate is unavailable, not a recorded zero. A real zero in selected zones is allowed only with explicit entries for every zone and positive recorded duration in other zones.
- Failures use existing compact metric/editor diagnostics. Changing a reading configuration clears the previous ring progress, preventing an old HR value from becoming mislabeled minutes. Same-configuration refresh errors keep the last valid reading. Widget failures retain only an exactly matching prior reading/date; no new fabricated zero snapshot is stored.
- iPhone and Watch query their own Health stores. Sync/availability differences can produce different readings or unavailable states; phone totals are not silently passed off as Watch observations.

No Health sample values are logged or written to docs. All fixture values are explicitly synthetic and simulator-gated.

## Verified publication

Version **2.0 (35.1)** uploaded successfully from exact source `872b7411f3ef45e617dbb16da3ed678cd5879b1d` in [run 43737045403](https://github.com/ptmt/anyring/actions/runs/43737045403), validation job `132881838385`, upload job `132890597719`. Apple explicitly reported **Uploaded package is processing.** and **Upload succeeded.** at `2026-11-15T17:17:44Z`, followed by **EXPORT SUCCEEDED**. Cleanup passed, zero artifacts; sibling push validation also passed. Processing completion and tester/device availability are not verified. This is the first workout-zone release: **OS 27+ and stored five-zone aggregates required**; app minimum 26 unchanged. Full release and failed-attempt evidence: [ci/RELEASE.md](../ci/RELEASE.md).

## Independent review / release gate

- Re-read all eleven Swift changes, Apple documentation JSON and the installed 27.2 HealthKit swiftinterface. Verified native parent aggregate access, zero-based indices, workout + HR read-only access, unchanged deployment minimum 26 and guarded OS 27 API access. OS 26 runtime is not installed/tested; the compile-time availability guard returns unavailable before the query/API path.
- Fixed only the false full-active-duration aggregate rejection with RED `zone-review-red.xcresult` and GREEN `zone-review-final.xcresult`. Added compatibility regression: unknown metric decoding fails closed, old configurations round-trip, and the old-client heartRate/sum payload returns unsupported aggregation before a Health query rather than a fabricated HR average.
- Final independent Release suite: **75 methods / 83 parameter-expanded executions**, zero failures, skips or xcresult runtime warnings (`zone-review-final.log/.xcresult`). Separate Release UI: **3/3** passed, covering both zone selections/names/45-minute goals/relaunch, dashboard and actual pull-to-refresh six-query/cache-date regression (`zone-review-ui.log/.xcresult`). All **23** offline signing/configuration tests and shell syntax checks passed; added-line security scan and `git diff --check` clean.
- Independent Watch Release build passed (`zone-review-watch.log`), preserving both Watch targets. Final production widget rendering `zone-review-attachments/EA67BD12-64C9-4E71-86F8-48F202A311E8.png` visually verified suffixes 2–3/4–5 and 20%/40%; compact Watch goal/name verified separately. These are synthetic Release ImageRenderer/simulator artifacts, not physical device evidence.
- Initial publication `43732349246` attempts 1/2 failed existing ten-second readiness assertions at ConfigurationTests.swift:830/914 under 17–23-second hosted render scheduling. All ten UI tests and five widget tests passed in both. Reused the existing 30-second readiness helper only for the two failed registrations, preserving exact counts, continuation fences and all product assertions; no production change. Local final full Release rerun (`zone-review-fixture-final.xcresult`) again passed 75 methods / 83 expanded executions. Sibling push Debug suite passed but the job reached its 30-minute budget in Release and was cancelled; it is not claimed green. No Apple upload occurred on that source.
- CI now runs the whole Release unit/render suite and the new workout UI regression alongside the existing Release background HealthKit and pull checks. Signing, bundle identifiers, icons and cleanup scripts unchanged. No App Store review submission or screenshot-pack overwrite.

## Execution evidence (implementation candidate)

All runs used the isolated iOS 27.2 simulator `25E25094-8D0D-4E0C-9996-91C1BEF0EECC` (AnyProgress workout zones isolated), not the active App Store screenshot simulators.

Final Release unit/integration/render run:

- `/Users/tinyserve/.hermes/cache/scratch/zone-delivery.xcresult`
- `zone-delivery.log`: 68 Swift Testing tests in 9 suites + 5 XCTest widget tests, zero failures, TEST SUCCEEDED. `xcresulttool get test-results summary` confirms **73 total tests passed**, zero failures; its device entry counts 81 parameter-expanded passes (2 tests have 10 dynamic-parameter runs).
- Covers known paired sums, actual SDK zero-based configuration, DST spring/fall windows, paused elapsed/active duration, parent UUID repeats, overlap rejection, boundaries, absent/invalid/sparse coverage versus recorded zero, source/config persistence, permissions, actual AnyRingViewModel concurrent workout reads, background continuation completion, late cancelled generations, metadata-only rename/no extra Health reads, matching cache/date, and existing async/endpoint/privacy regressions.
- Earlier RED captures: `zone-red.log` missing workout source; `zone-red2.log` missing source selection/config; `zone-red3.log` sparse coverage incorrectly returned zero; `zone-red4.log` previous HR value persisted as workout minutes. Corresponding final regressions pass.

Actual Release UI acceptance:

- `/Users/tinyserve/.hermes/cache/scratch/zone-final-ui.xcresult`, `zone-final-ui.log`: **1 test, zero failures**, TEST SUCCEEDED.
- Selects each metric from real picker, edits minute goals to 45, saves separate names, selects 5 days, terminates/relaunches with explicitly retained simulator fixture and verifies first metric/name/goal persistence. Earlier `zone-ui5.xcresult` also passed and exported editor screenshots show restored 45 min without clipping.
- Goal-entry UI regression exposed concatenation when clearing the numeric field; workout goal uses a draft string so an empty editing buffer is not immediately rewritten. Existing non-workout goal editing is unchanged.
- Some combined UI reruns timed out after the isolated simulator became unbooted; booting only this task's simulator and splitting the runs produced the successful final unit and UI results. No other simulator was reset/shut down.

Final watch Release build: `zone-watch-delivery.log`, **BUILD SUCCEEDED**, includes WatchRingWidgetExtension. iOS Release builds compile the iPhone app, phone widget, embedded Watch app and Watch widget with deployment minimum 26 unchanged.

Exported actual compact Watch metric and accessory widget renderings are under `zone-delivery-attachments`. The rectangular widget originally tail-truncated the two labels identically; middle truncation now keeps both 2–3 and 4–5 plus fixed-width percentages visible. Visually inspected final rectangular render `09E24930-BDA0-4077-94F3-1826D5BA8483.png`: zone suffixes and 20%/40% readable. Compact Watch renders retain full zone name and minute goal. Existing privacy pixel-equality tests pass. These are ImageRenderer/Release simulator checks, not physical Watch evidence.

Unsigned simulator HealthKit emits the existing missing-entitlement diagnostics during app startup. They are not production Health readings or evidence of live Health availability. Physical HealthKit data, historical real-zone backfill, actual pause semantics across recording apps, paired-device reconciliation and OS 26 runtime behavior were **not physically tested**; no production-value claim is made.
