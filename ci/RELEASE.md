# AnyProgress releases

## Compact dashboard — 2.0 (37.1)

- Release source: [`34142b2f3bfe42e3ba602cf81f522cc8095ce78d`](https://github.com/ptmt/anyring/commit/34142b2f3bfe42e3ba602cf81f522cc8095ce78d), based on freshly fetched `c23364b2c0f7ad653271fe116fd614b7c287590d`. Scoped seven Swift files plus [dashboard documentation](../docs/COMPACT-DASHBOARD.md). Removes iPhone top-title/direction chrome, enlarges graph, adds rolling seven-day included-period strip and inline existing presets, and unifies shape/palettes under Appearance.
- [Release run 43939623194, attempt 1](https://github.com/ptmt/anyring/actions/runs/43939623194): **success**, exact head SHA above. Validation **133553353875**, upload **133575831719**. Logged archive/upload build **37.1**; marketing version **2.0** retained.
- Apple at `2026-11-16T20:11:53Z`: **Uploaded package is processing.**, **Upload succeeded.**, then **EXPORT SUCCEEDED**. Signed archive succeeded; all four original profiles validated original team/bundles, HealthKit, App Group, dates and certificate membership. Logs show signing of iPhone, iPhone widget, Watch and Watch widget. Signing cleanup succeeded; zero GitHub artifacts. Processing completion and tester availability remain unverified. No App Review submission.
- Fresh local full Release **91 methods / 99 expanded executions**; exact final warning-corrected source **81 / 89**, all unit/render plus compact UI on dark SE; zero failures/skips/runtime warnings. Watch Release build and **23** offline signing/CI checks pass. Final hosted Debug: **73 Swift Testing methods + six XCTest lifecycle/widget methods + 12 UI methods**, all passed. Hosted Release: same unit/render suite + three existing UI regression methods, all passed. Push-only [43939605661](https://github.com/ptmt/anyring/actions/runs/43939605661), validation **133553283063**, also succeeded and skipped upload.
- Independent review found a midnight strip/readings mismatch; corrected by calendar-aligned ticks and a changed-day refresh through the existing model. Actual hosted SwiftUI regression failed RED before the fix, then passed midnight/timezone callbacks and minute no-op. Added five-timezone/boundary arithmetic, real home/foreground queries, and period/shape/palette cold relaunch checks. Final review PASS; provider/formula/goal/baseline/identity, async HealthKit, custom names, workout zones, widgets, Watch connectivity, icon and manual signing configuration unchanged.
- Normal non-force push from isolated `anyring-compact-dashboard`; original `/Users/tinyserve/Projects/anyring` HEAD `2552ee52e2339f00828e82615aaa63903af4cede`, all 13 dirty-file hashes and exact status preserved. No real Health samples used. Physical Watch/HealthKit and OS timezone-change/overnight behavior remain unverified; injected lifecycle tests are not physical acceptance.
- Evidence under `~/.hermes/cache/scratch/compact-release-*` plus `compact-rollover-{red,green}.xcresult` and `compact-original-before.json`: source patch, reviews, summaries, screenshots, full CI build/upload logs and run JSON. After verified upload, removed only this task's three regenerable DerivedData directories (`compact-release-derived`, `compact-rollover-derived`, `compact-release-watch-derived`), reclaiming **1688162304 allocated file bytes**. All xcresults/evidence, worktrees and unrelated artifacts retained; cleanup manifest `compact-release-cleanup.json`.

## Workout-only heart-rate zone minutes — 2.0 (35.1)

- Release source: [`872b7411f3ef45e617dbb16da3ed678cd5879b1d`](https://github.com/ptmt/anyring/commit/872b7411f3ef45e617dbb16da3ed678cd5879b1d), feature `777d5568c9a3bf320327a6dec836a8d8c2ef4a96` plus test-readiness/CI budget correction, atop `f9ff0bd`. Two Workouts selections sum stored parent HKWorkout heart-rate zones 2–3 or 4–5, in minutes. **First release requires iOS/watchOS 27+ and stored five-zone aggregates**; app deployment minimum remains 26 with explicit unavailable response. [Independent review, architecture and limits](../docs/WORKOUT-ZONE-METRICS.md).
- [Release run 43737045403, attempt 1](https://github.com/ptmt/anyring/actions/runs/43737045403): **success**, exact head SHA above. Validation **132881838385**, upload **132890597719**. Archive/upload build **35.1**, marketing version **2.0** retained.
- Apple at `2026-11-15T17:17:44Z`: **Uploaded package is processing.**, **Upload succeeded.**, then **EXPORT SUCCEEDED**. Signed archive succeeded; all four original profiles validated team/bundles, HealthKit, App Group, dates and certificate membership. Signing cleanup succeeded; zero GitHub artifacts. Processing completion, tester availability and physical acceptance remain unverified.
- Independent local Release **75 methods / 83 expanded executions**, three separate Release UI tests, **23** Python checks, and Watch Release build passed. Hosted full Debug: 70 Swift Testing methods + five widget XCTest + ten UI methods; separate Release: same unit/render suite + three UI methods, all passed. Existing background HealthKit crash, native pull six-query/cache-date, privacy, custom names, persistence and endpoint regressions retained. Push-only [43737044678](https://github.com/ptmt/anyring/actions/runs/43737044678), validation **132881832503**, also succeeded and skipped upload.
- Review fixed false rejection of valid stored aggregates whose duration does not equal full active duration; RED/GREEN captured. No raw-HR sampling reconstruction, average-HR fallback, pause resubtraction or parent/activity double count. Missing entries, ambiguous overlaps and clipped boundaries explicitly unavailable; duplicate UUIDs deduplicated. Stored custom five-zone configurations accepted as recorded; no claim of uniform physiological thresholds across workouts.
- Initial source publish [43732349246](https://github.com/ptmt/anyring/actions/runs/43732349246), attempts 1/2, failed existing ten-second fixture registration deadlines under 17–23-second render load; all ten UI tests passed. Reused existing 30-second helper for only those two assertions, preserving exact query counts. Increased validation budget to 50 minutes to fit full Debug plus Release gates; no product/signing change. Initial sibling push hit its 30-minute timeout. No Apple upload occurred until final source.
- Original `/Users/tinyserve/Projects/anyring` 13 dirty files untouched; normal non-force publication from isolated feature worktree. Icons, four shipping target IDs, custom labels, native refresh cleanup and signing scripts retained. No new App Store review submission or changes to the separate 31.3 screenshot pack. No real Health samples used. First-release exclusions: activity-only aggregates, non-five-zone configurations, distinct overlaps, boundary clipping; OS 26 runtime and real pause/backfill/paired-device behavior not physically tested.
- Concise logs, RED/GREEN xcresults and render attachments retained under `~/.hermes/cache/scratch/zone-review-*`. No build scratch deleted without separate approval.

## Per-ring custom names — 2.0 (31.3)

- Release source: [`d33b3e8c91823c79aac228f90b59c43eb7c2e82b`](https://github.com/ptmt/anyring/commit/d33b3e8c91823c79aac228f90b59c43eb7c2e82b), feature `855a62a978feebba015f3c5c2cc7c92721b488f8` plus test-only readiness correction, atop the prior docs-only `c2ee4607efef4df1ca68fb5322880c8b1acbf776`. Optional trimmed 40-grapheme names retain original metrics, goals, progress and cache dates; shared phone/Watch/widget/accessibility display. [Scope and independent review](../docs/CUSTOM-NAMES.md).
- [Release run 43701626684, attempt 3](https://github.com/ptmt/anyring/actions/runs/43701626684): **success**, exact head SHA above. Validation job **132785638803**, upload job **132792416014**. Logged build **31.3**, marketing **2.0** retained.
- Apple at `2026-11-15T11:15:51Z`: **Uploaded package is processing**, **Upload succeeded**, then **EXPORT SUCCEEDED**. All four original profiles validated (team/bundles, HealthKit, App Group, dates, certificate membership); signed archive retained phone, phone widget, Watch and Watch widget. Cleanup succeeded; zero GitHub artifacts. Processing completion and tester availability remain unverified.
- Final local Release, including test-only correction: **73 methods / 81 parameter-expanded executions**, zero failures/skips/runtime warnings; **23 Python tests**. Actual rename/relaunch/clear/XXXL UI, JSON compatibility/type validation, pending reads, Watch snapshots, privacy pixels, six-query native pull/cache-date and endpoint regressions passed. Actual rendered widget percentages inspected. No real Health samples used.
- Hosted final full Debug suite (**60 Swift Testing methods, four widget XCTest methods, nine UI tests**), simulator build, unsigned four-target archive, and separate Release background HealthKit/native-refresh UI checks passed. Push-only [43701616156](https://github.com/ptmt/anyring/actions/runs/43701616156), validation **132773778031**, also succeeded and correctly skipped upload.
- Initial `855a62a` publish/push failed existing fixed-sleep fixture races. Test-only `d33b3e8` waits for registered queries and uses disjoint continuation ranges, preserving all assertions. Final publish attempt 1 hit existing 10-second readiness deadlines under ~22-second rendering load; attempt 2 had only an Xcode UI launch timeout (`Tests_iOS.swift:219`). Same-SHA push was green; two failed-job reruns on unchanged source culminated in attempt 3 success. No checks weakened, no production changes after review, no duplicate Apple uploads. Failure logs retained.
- Normal non-force publication from isolated `anyring-custom-names-release`; original main HEAD and all 13 dirty-file hashes unchanged, implementation candidate untouched. Dark concentric icons, seamless endpoints, prior refresh cleanup, all identifiers/profiles and HealthKit adapters unchanged. Physical Watch/installed widget/live permission acceptance remains outstanding.
- After verified upload, tool-approved cleanup removed only this review's `build`, `release-review.xcresult`, `release-final.xcresult`, and `release-fixture-fix.xcresult` under `~/.hermes/cache/scratch/anyring-custom-names-review/` (**543555584 allocated file bytes**). Compact JSON/test summaries, screenshots, raw CI logs, patch and hash manifest retained. No other task scratch, source, simulator or signing assets touched.

## Native iPhone refresh cleanup — 2.0 (27.2)

- Release source: [`ed9017de67fceb55f857e6f4341e76e165a22ef8`](https://github.com/ptmt/anyring/commit/ed9017de67fceb55f857e6f4341e76e165a22ef8), including UI commit `0e32c50b955957d61d7078cf3a6d242d7a607ad1`, based on `0c3c9214fcebc067801af18b22d08fe8162eb451`. Dark concentric icon and all Watch/settings/widget/privacy/async behavior preserved. [Scope and test evidence](../docs/NATIVE-REFRESH.md).
- [Release run 43693772893, attempt 2](https://github.com/ptmt/anyring/actions/runs/43693772893) **success**, exact `headSha` above. Validation job **132753201154**, upload job **132758191451**. Logged archive/upload build **27.2**, marketing version **2.0** retained.
- Apple at `2026-11-15T08:56:49Z`: **Uploaded package is processing**, **Upload succeeded**, then **EXPORT SUCCEEDED**. Signed archive succeeded with all four bundles, signing cleanup succeeded, zero GitHub artifacts. Processing completion and tester availability are not verified.
- Local full Release: **62 methods / 70 parameter-expanded executions**, including seven UI tests, passed. Real drag required six new datasource queries and a newer persisted matching reading; disconnected-callback negative control failed. No-button/no-sync-header test was RED before cleanup, GREEN after. 23 configuration/signing tests passed. Independent read-only code reviews found no security or logic issues.
- Hosted final full Debug suite, simulator build, unsigned Release archive, and separate Release HealthKit + no-chrome + gesture UI regressions passed. Push-only [43693772536](https://github.com/ptmt/anyring/actions/runs/43693772536) also succeeded and skipped upload.
- First source's [43692038411](https://github.com/ptmt/anyring/actions/runs/43692038411) failed because localized test telemetry split into five fields (Tests_iOS.swift:161/167). Reproduced locally with en_US, corrected only simulator telemetry using `Text(verbatim:)`, retained explicit-locale regression, then published the corrected source. No upload occurred on the failed source.
- Final attempt 1 passed the gesture but hit an existing fixture scheduling deadline at `ConfigurationTests.swift:450` (`source.reads.count == 9`). Raw job logs retained. Same-SHA push suite passed; rerunning failed publication jobs on unchanged source passed. No tests weakened or async fences changed; exactly one Apple upload succeeded.
- Published non-force from clean `anyring-native-refresh`; original dirty worktree's 13 file hashes verified unchanged. Evidence: `~/.hermes/cache/scratch/anyring-native-refresh/`, including screenshot exports and raw CI logs. No unrelated app or signing configuration changes.

## Approved dark concentric Graphite icon — 2.0 (23.2)

Published under the owner's continuing icon-release authorization; "справа" selected the right-hand constant-offset design.

- Release source: [`32ef1a739f643f90c5329c3bafbeedfe47341046`](https://github.com/ptmt/anyring/commit/32ef1a739f643f90c5329c3bafbeedfe47341046), based on fetched `bbee324e9e41067be1f509ca8a42792d612ff91b`. Changes: **55 icon PNGs in three existing appiconsets plus documentation only**. No production renderer, HealthKit, target, project, profile or workflow change; the 20.1 endpoint fix is retained.
- [Release run 43635294808, attempt 2](https://github.com/ptmt/anyring/actions/runs/43635294808), **success**, exact `headSha` above. Validation job **132576301260**; upload job **132579883434**. Logged archive/upload build **23.2**, marketing version **2.0**.
- Apple at `2026-11-14T20:38:37Z`: **“Progress 100%: Uploaded package is processing.”**, **“Progress 100%: Upload succeeded.”**, followed by **`** EXPORT SUCCEEDED **`**. Processing completion and tester availability are not verified.
- All four profiles validated original team/bundles, HealthKit, App Group, dates and certificate membership. Signed archive retained phone, phone widget, Watch and Watch widget; signing cleanup succeeded; GitHub reports zero artifacts.
- Hosted configuration tests, simulator build, unsigned Release archive, complete app/widget/UI suite and separate Release HealthKit regression passed. Local 23 configuration/signing tests and all three real `actool` catalog compilations passed. [Asset verification](../docs/DARK-ICON-VERIFICATION.md) records master SHA-256 `7f60d6dd1a42673c72e0089a8c4668d191b69c480677f40df27fad3f56219134`, RGB/sRGB/dark-corner checks, all 55 hashes and byte-identical 1024px slots.
- Attempt 1 failed before upload because XCTest could not terminate the app in `Tests_iOS.swift:8`. Push-only [43635285319](https://github.com/ptmt/anyring/actions/runs/43635285319) failed at `Tests_iOS.swift:23` with an Xcode application-launch timeout. Raw job logs retain both errors. Retried only the failed publication jobs on the **unchanged SHA**; all checks passed. No test weakening, new dispatch or duplicate Apple upload occurred; the push run remains failed and is not claimed green.
- Published with a normal non-force push from new clean `anyring-dark-concentric-release`; original dirty worktree's 13 file hashes remain unchanged. Only this task's three compiled `actool-*` directories were deleted after verified upload with tool approval (860160 allocated file bytes before deletion); source art, previews, verification/log evidence, worktrees and other tasks' scratch remain untouched. No local DerivedData or xcresult was created by this icon-only task. Older cleanup approval gates were not bypassed.

## Graphite icon + seamless endpoints — 2.0 (20.1)

Published with the owner's explicit authorization on 2026-11-14.

- Final source: [`79e67fdc95287f15e9e32a464e249718358ff453`](https://github.com/ptmt/anyring/commit/79e67fdc95287f15e9e32a464e249718358ff453): Graphite icons (`5cd05fd`), endpoint compositing (`67ee799`), and a narrow test-fixture scheduling correction (`79e67fd`). Production changes are confined to icon assets and `TripleRing.swift`; no HealthKit/data/feature removal.
- [Release run 43609004987, attempt 1](https://github.com/ptmt/anyring/actions/runs/43609004987), **success**; validation job **132489688262**, upload job **132495908549**. Archive/upload build **20.1**, marketing version **2.0**.
- Apple at `2026-11-14T15:39:39Z`: **“Progress 100%: Uploaded package is processing.”**, **“Progress 100%: Upload succeeded.”**, followed by **`** EXPORT SUCCEEDED **`**. Processing completion and tester availability are not verified.
- All four profiles validated with original team/bundles, HealthKit, App Group, dates and certificate membership. Signed archive retained phone, phone widget, Watch and Watch widget. Signing cleanup succeeded; GitHub reports zero artifacts.
- Hosted configuration tests, simulator build, Release archive, complete app/widget/UI test step and separate Release HealthKit regression all passed. Final push-only [43609004992](https://github.com/ptmt/anyring/actions/runs/43609004992) also passed (validation **132489684018**) and correctly skipped upload.
- Local final app/widget suites passed in Debug and Release: **53 Swift Testing methods + 2 widget XCTest methods** (63 parameter-expanded executions); final six UI tests passed separately. Endpoint candidate's full Debug/Release suites also passed all 61 methods each (69 expanded executions), including **693 real ImageRenderer renders** per suite; iOS/watchOS builds and actual synthetic Watch harness evidence were reviewed. See [ENDPOINT-VERIFICATION.md](../docs/ENDPOINT-VERIFICATION.md).
- Failed pre-final attempts were investigated, not hidden: icon-only push hit a no-process-ID UI launch failure; combined initial dispatch hit AX initialization timeout, then a pre-existing fixed-sleep test-fixture race exposed by rendering load. The fixture now waits for registered reads and requires the count before resuming continuations. No product behavior or test assertions were removed. Previous combined run `43605540520` never uploaded.
- Earlier **icon-only 17.1** was separately uploaded by [43603667164](https://github.com/ptmt/anyring/actions/runs/43603667164), validation **132473573034**, upload **132477250148**, Apple processing/upload success at `14:29:22Z`. It was not restarted and must not be described as containing the endpoint fix.
- Publication used normal non-force pushes from `anyring-graphite-release`; the original dirty worktree's 13 files still match the original backup hashes. All worktrees, user artwork and backups are retained. Scoped post-release build-scratch deletion was requested but paused by the tool's approval gate; no reclaimed-byte claim is made yet. Evidence remains under `~/.hermes/cache/scratch/anyring-combined-release/`.

## Combined laptop features + async HealthKit — 2.0 (14.1)

Published with the owner's explicit authorization on 2026-11-13.

- Source: [`47c90baa4f8cdcbf67f5dcd95278a83ae518e7ed`](https://github.com/ptmt/anyring/commit/47c90baa4f8cdcbf67f5dcd95278a83ae518e7ed), directly atop fetched `48da9cbdfc6cdd33a6e1b4f8f0e523d6dcfabfc2`.
- [Release run 43478754953, attempt 1](https://github.com/ptmt/anyring/actions/runs/43478754953), **success**; validation job **132069440932**, upload job **132078757570**.
- Marketing version **2.0**, archive/upload build **14.1**. Signed archive and export both succeeded. Apple explicitly reported **“Uploaded package is processing.”** and **“Upload succeeded.”** at `2026-11-13T18:23:38Z`.
- Hosted checks passed: 23 signing/configuration tests, simulator build, unsigned Release archive, 48 Swift Testing methods, two widget-render tests, six UI tests, and the separate Release HealthKit suite (two parameterized methods, ten cases). Full local Debug/Release evidence and independent review are in [HEALTHKIT-ASYNC.md](../docs/HEALTHKIT-ASYNC.md).
- All four original bundle IDs, team `49PJNAT2WC`, App Group, HealthKit, Watch app and Watch widget were validated and signed using the existing CI assets. Cleanup succeeded; GitHub reports zero artifacts. No signing/configuration changes were required.
- The push-only [run 43478755068](https://github.com/ptmt/anyring/actions/runs/43478755068) also succeeded and correctly skipped upload. Exactly one publish dispatch was issued; no retry or duplicate upload was needed.
- Latest verified Apple state is **processing started**, not processing completed or tester availability. App Store Connect browser access required login and had no saved credentials; no account access or new credentials were requested just to infer availability. Physical acceptance of this combined build remains outstanding; the owner had accepted 12.2's crash fix.

### Safe integration publication

Publication used the clean `/Users/tinyserve/Projects/anyring-integration-review` worktree on `review/laptop-async-integration`: fetch, verify the exact reviewed SHA and `origin/main` ancestry, normal non-force `git push origin HEAD:refs/heads/main`, read back the remote SHA, then one `gh workflow run testflight.yml -R ptmt/anyring --ref main -f publish=true`. Pushes only validate; the manual publish flag is required for signing/upload. Follow the exact run through completion before recording evidence in a documentation-only `[skip ci]` commit.

The original `/Users/tinyserve/Projects/anyring` dirty main was not checked out, reset, stashed or overwritten. Its HEAD and all 13 changed/untracked file hashes match `/Users/tinyserve/.hermes/backups/anyring-integration-20261113-184157/manifest.json` after publication. The combined release retains the laptop shape/palette/animation/sync/display-unit features and the async HealthKit implementation.

## Earlier Lock Screen widget release

## Scope and local verification

The authorized release includes the existing circular/rectangular/inline widgets,
matching real-health cache, privacy-safe geometry, and strict widget deep links.
All four original phone/Watch app and widget bundle IDs, team `49PJNAT2WC`,
HealthKit, and `group.49PJNAT2WC.com.potomushto.AnyRing` are preserved.

The local checkout was six commits behind origin/main. Those remote CI changes
were fast-forwarded before integrating the local widget work. The owner's short
README/name-review note is preserved; detailed app documentation is in `docs/APP.md`.

Verification on Xcode 27.2:
- 25 Swift unit/regression tests, two production-widget rendering tests, and four
  UI tests passed (31 total).
- Initial period-persistence UI test failed because its second launch removed the
  explicit fixture flag, correctly activating real HealthKit instead. Relaunch now
  retains the fixture flag with a separate preserve-settings flag; production
  simulator launches still use real HealthKit. The complete suite then passed.
- Unsigned Release device archive including both Watch targets passed.
- 22 offline signing/metadata/profile-ownership tests passed, as did ShellCheck,
  bash syntax, plist syntax, and actionlint (only its stale runner label check is
  narrowly excluded; the actual runner was verified from GitHub logs).
- Scoped source/diff review found no hardcoded credentials. Parent-agent independent
  verification is separate; this commit does not claim an independent reviewer verdict.

## Delivery

Apple upload **succeeded** in [run 43433248233, attempt 2](https://github.com/ptmt/anyring/actions/runs/43433248233).

- Release head: `6c6387a306c52f0f34de036116911d8f4d6f9722` (includes widget commit `c02d6f98b79d43dd185176c2abc0f9d6f4ab0d27`).
- Marketing version: `2.0`; archived/uploaded build: **10.2**.
- Validation job: **131918537263**; upload job: **131922384997**.
- Hosted validation: **23** Python tests and **31** Swift/widget/UI tests passed;
  simulator build and unsigned Release archive also passed.
- Hosted signing validated all four profiles' original team/bundle IDs, HealthKit,
  App Group, validity dates, and exact distribution-certificate membership.
  The signed archive succeeded with both Watch targets retained.
- Apple's output at `2026-11-13T13:49:53Z`: **“Progress 100%: Upload succeeded.”**,
  **“Uploaded package is processing.”**, followed by **`** EXPORT SUCCEEDED **`**.
- Cleanup step succeeded; GitHub reports **zero artifacts** for this run.

The first publication (run 43430329177, build 8.1) passed signing but Apple rejected
it because the Watch app lacked `NSHealthUpdateUsageDescription`. Added the truthful
read-only purpose string and a RED→GREEN regression covering every HealthKit plist.
Attempt 1 of the final run hit a hosted simulator launch timeout before assertions;
its sibling push run passed. Rerunning the failed jobs on the same unchanged SHA
passed all tests and delivered build 10.2. No checks or Watch capabilities were dropped.

Upload is verified; Apple processing completion, compliance, tester assignment,
and availability on a physical device are **not** yet verified.

## HealthKit crash hotfix — 2.0 (12.2)

The subsequent on-device 10.2 crash report matched an independently reproduced
Release simulator executor assertion in the HealthKit progress transform. The fix,
RED/GREEN evidence and physical-report correlation are in `docs/HEALTHKIT-CRASH.md`.

- Source: `5d9b0dd19d79b68959ad05d7d199752545c60418`.
- [Run 43461305997, attempt 2](https://github.com/ptmt/anyring/actions/runs/43461305997): validation `132019554019`, upload `132028928533`, both success.
- Signed archive and explicit Apple **Upload succeeded** verified; build **12.2**,
  marketing version **2.0**. Apple reported processing at `2026-11-13T16:55:44Z`.
- All four shipping targets/capabilities preserved; cleanup success, zero artifacts.
- Full Debug and Release tests passed locally; hosted validation includes the full
  Debug suite plus the new Release background-callback regression. Independent
  code review passed. Attempt 1 had a hosted UI launch timeout; unchanged retry passed.
- The owner subsequently confirmed that 12.2 no longer crashes on their iPhone.
  This acceptance does not establish the combined 14.1 build's device behavior.
  Do not ask for another crash report to identify the original failure: the
  supplied report has already been correlated.

## Device acceptance still required

After Apple processing and tester assignment, verify actual iPhone Lock Screen
installation, locked HealthKit/cache behavior, privacy/Always On, and paired Watch
configuration/complication updates. Automated rendering does not install a widget.
