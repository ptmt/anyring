# HealthKit one-shot async simplification (local review branch)

## Scope and status

The user confirmed that TestFlight **2.0 (12.2) no longer crashes on their iPhone**, then requested a simpler implementation. This follow-up changes the one-shot HealthKit → progress/refresh pipeline and its immediate widget/UI consumers. It is integrated with the laptop features, independently reviewed, and locally verified; it is **not uploaded or physically accepted as a new release**.

Original async baseline: `2552ee52e2339f00828e82615aaa63903af4cede`, including the proven `5d9b0dd` scheduler fix. Integration base: `48da9cbdfc6cdd33a6e1b4f8f0e523d6dcfabfc2`. The combined tree lives on local branch `review/laptop-async-integration`, worktree `/Users/tinyserve/Projects/anyring-integration-review`. Original `main`, its dirty files, and remote refs remain unchanged. No pull, reset, discard, stash-drop, push or TestFlight action was performed. Earlier evidence below describes the pre-integration implementation; combined verification is recorded at the end.

## Changes

- Async/throwing methods replace `Future`, type-erased one-shot publishers, `tryMap`, scheduler operators and sink completion/value bookkeeping through the data source, provider and view models.
- `HKStatisticsQueryDescriptor.result(for:)` replaces the manually executed statistics query callback. The same strict-start date window, aggregation checks, unit compatibility and missing-sample policy remain.
- Authorization uses a checked continuation to preserve **false versus thrown error**. Apple's native async authorization overload returns Void and throws on false; silently adopting it would change the existing UI distinction. The system authorization prompt is not cancellable; canceled callers discard its eventual result.
- MainActor resumption after `await` replaces the explicit scheduler boundary. No `assumeIsolated`, unchecked isolation conversion or new unchecked Sendable conformance was added. The existing legacy callback wrapper remains only for WidgetKit/WatchConnectivity callback APIs.
- Each ring owns a cancelable task with the existing generation fence. Each snapshot request owns a throwing task group, so all three metrics remain concurrent and independent widget requests cannot cancel each other. Replacing the app's cache-refresh task cancels obsolete work; matching configuration and generation checks still guard cache writes.
- Snapshot computation captures immutable configuration at request start. Characterization discovered the old callback read `provider.config.appearance` **after** completion, allowing old readings to use new colors. A failing Release test was added, then a minimal capture fix passed before the async refactor.
- Last good progress remains on read failure. Missing samples and authorization denied remain errors, not invented zero readings. Cache failures retain the previous matching reading/date. Storage, migration, capabilities, bundle identifiers and Watch transport are unchanged.

Combine remains in the observable models for `ObservableObject` / `@Published`, and elsewhere for existing lifecycle/event notifications. It no longer carries one-shot HealthKit results. The HealthKit observer callback remains a long-running event bridge with the existing stop-old-observers behavior; it dispatches refresh onto MainActor.

## Inline simplification review

This was a leaf agent: **all four angles were reviewed inline**, not four independent agents.

| Angle | Finding and action | Confidence / risk |
| --- | --- | --- |
| Reuse | `HealthKitProvider`'s aggregate helper only forwarded one read and erased its type. Inline its calendar window into the async method; reuse existing `quantityValue` validation and cache/persistence. | High / careful |
| Quality | Future/promise/scheduler/map/sink layers described one result; replace with async/throws. Remove unused provider cancellable and unused demo authorization publisher. Keep generation state: it protects against non-cooperative callbacks. | High / careful |
| Efficiency | Use native one-shot query lifetime and task cancellation. Snapshot child queries remain concurrent, not a serial await loop. Preserve independent caller ownership. Do not broaden into query deduplication/shared UI-cache refresh redesign. | High / careful |
| Altitude | The crash arose before a downstream UI scheduler. Actor-isolated async provider methods eliminate that entire synchronous callback-transform path, rather than adding another scheduling wrapper. Keep the Release background-completion regression. | High / careful, concurrency-sensitive |

Production Swift net change: **62 fewer lines** before upstream integration (tests/docs excluded). Review checked git history/blame before removing the old wrappers and request-owned cancellation behavior.

## Verification and evidence

Local evidence: `/Users/tinyserve/.hermes/cache/scratch/anyring-health-async/`.

- `characterize-2.xcresult` / `.log`: Release baseline passed existing tests and new concurrency/stale-refresh/stale-authorization tests; the new immutable-snapshot test failed on old colors (three component assertions).
- `characterize-green.xcresult`: minimal immutable configuration capture fixed that regression, before async changes; 31 Swift Testing methods and two widget rendering tests passed.
- `final-release.xcresult`: final async implementation passed **33 Swift Testing methods**, **two widget rendering tests**, **four UI tests**. The existing background/main completion suite retains populated/empty/denied, new/legacy settings, authorization false/error and actual UI/cache assertions (10 parameter combinations).
- `final-debug-retry.xcresult`: the same full suite passed in Debug. `full-debug.xcresult` also passed; an intervening `final-debug.xcresult` failed two assertions in the single provider-search UI test after a failed scroll-to-visible retry. An unchanged full rerun passed; no check was disabled. This intermittent UI automation failure is not claimed fixed.
- Added tests cover simultaneous multi-metric snapshot calls, late canceled-ring completion, stale authorization, immutable configuration, persisted goal edits, calendar window, pre-canceled reads, cancellation isolation across snapshot requests, and task cleanup when the view model is released.
- `device-build.log`: unsigned Release build for generic iOS succeeded, including embedded Watch and widget targets. `watch-build.log`: explicit Release Watch simulator build succeeded.
- `signing-tests.log`: 23 offline signing/configuration tests passed. `git diff --check` passed. Added-line scan found no credential assignments, Health logging, or unsafe isolation additions.
- Existing original crash RED/GREEN evidence remains under `anyring-health-crash/`; no attempt was made to replace that causal evidence with a synthetic claim of a second device crash.

The SDK's native query owns query execution/cleanup. Automated cancellation tests exercise the production provider/task ownership with a cancelable synthetic data source; they do **not** instrument Apple's internal `HKHealthStore.stop` or establish physical-device HealthKit cancellation timing. No Health samples were logged or accessed. Unsigned simulator hosts still emit the known missing HealthKit entitlement warning. Device acceptance applies to 12.2, not this unuploaded refactor.

## Integrated laptop features and verification

All five overlap files were reviewed: `ConfigurationTests.swift`, `RingWidget.swift`, `HealthKitProvider.swift`, `AnyRingViewModel.swift`, `RingViewModel.swift`. Metric descriptions/display units, goal labels, `updateShape`, FakeWatchTransport peer delivery, and all three new upstream feature test suites are retained. The widget conflict was resolved with async loading **and** `shape: config.global.shape`; accessory circular and other shape rendering remain intact. Sixteen nonoverlapping upstream feature files remain byte-identical; only the two fixes below additionally touch upstream files. Project metadata, all bundle IDs and HealthKit/App Group/Watch entitlements are unchanged.

Three narrowly scoped issues were demonstrated and fixed:

- `full-release.xcresult` reproduced the upstream contour test failure: duplicate-point filtering retained a near-identical final capsule endpoint, rather than the exact first point. Canonicalizing the closing point fixes the existing exact-closure test without relaxing its assertion.
- The same run reproduced the upstream shape persistence UI failure: dropping fixture launch arguments on relaunch switched to unsigned real HealthKit and its error screen. The test now uses the existing `--ui-testing --preserve-test-settings` relaunch convention; the Heart assertion is unchanged.
- `shape-red-2.xcresult` ran one new test and failed because a shape edit cleared the widget cache without rebuilding it. `updateShape` now requests a matching widget snapshot, as period/goal edits do. Additional coverage exercises obsolete completions after shape changes and failed reads retaining the last good value/date.

Combined evidence: `/Users/tinyserve/.hermes/cache/scratch/anyring-integration/`.

- **Full Release and Debug pass:** `final-release-green.xcresult` and `final-debug.xcresult`, exit 0. Each reports **56 test methods passed, zero failed/skipped**: 48 Swift Testing methods (including shape/rendering/sync and background HealthKit regression), two widget-rendering XCTest methods, six UI methods. Parameter expansion yields 64 executions per configuration.
- `final-device-build.log`: unsigned generic iOS Release build succeeded with embedded Watch/widget targets. `final-watch-build.log`: explicit Watch simulator Release build succeeded.
- `signing-tests.log`: 23 offline signing/configuration tests passed. Shell syntax, `git diff --check`, conflict-marker and added-line security/isolation scans passed.
- `review-final.txt`: independent read-only Codex review passed with no security or logic blockers. The four simplification angles were reviewed inline, not a four-agent fan-out. The initial CLI model was unsupported; an available model completed the review. Earlier reviewer noted a pre-existing Watch transport-success acknowledgement path, left unchanged rather than broadening sync scope.
- Intermediate `final-release.xcresult` passed all UI/render/contour checks but exposed incorrect hardcoded default-goal assumptions in two new test assertions. Those assertions now use the configured goal, without changing production data or defaults. The first narrow test command omitted Swift Testing parentheses and ran zero tests; only the corrected `shape-red-2` run counts as RED evidence.

Durable private recovery (outside auto-pruned scratch): `/Users/tinyserve/.hermes/backups/anyring-integration-20261113-184157/` contains a complete `all-local-including-untracked.patch`, separate staged/unstaged patches, `local-files.tar`, and SHA-256 manifest for all 13 original changed/untracked files. Original files were compared against the manifest after integration. Nothing was discarded.

**Ready for local merge/release preparation, not publication without authorization.** Physical acceptance still applies only to 12.2; this combined async build still needs real iPhone/paired-Watch/widget acceptance. Native HealthKit cancellation timing is not established by the synthetic tests.
