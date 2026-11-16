# Compact dashboard

Owner authorized normal push to main and TestFlight publication on 2026-11-16. No further design approval is required; no App Review submission is authorized by this release.

## Scope

Isolated worktree `/Users/tinyserve/Projects/anyring-compact-dashboard`, branch `feat/compact-dashboard`, based on freshly fetched origin/main `c23364b2c0f7ad653271fe116fd614b7c287590d` (source `872b7411f3ef45e617dbb16da3ed678cd5879b1d`, documented TestFlight 35.1). Original worktree's 13 dirty entries untouched.

- iPhone overview removes the navigation bar itself, not merely its title. Ring editors and shape gallery retain navigation. Graph size 210 → 250 points.
- iPhone metric rows keep name/value/goal inequality/progress/errors; omit direction captions and starting baseline. Settings retain those controls. Native watchOS metric layout unchanged; compact iOS rendering harness keeps its explanatory detail.
- One rolling seven-calendar-day strip near graph, ending today, highlights last N contiguous days. Read-only day cells have full-date accessibility labels and included/not-included values; continuous fill and underline avoid implying arbitrary individual-day selection. Current-day text is separate. A 44-point-minimum Menu selects existing 1/2/3/5/7 presets (retains an existing legacy count in menu without changing persistence semantics).
- Existing updatePeriod path performs queries, invalidates configuration-matched cache, fences outdated results and publishes Watch configuration unchanged.
- Appearance unifies shape and all 18 palettes, with selected checkmark/accessibility trait determined from actual appearance; per-ring custom color editors unchanged. All 11 shapes remain available.
- No Health samples logged or real Health store read: simulator fixtures only. No credential or signing-configuration changes.

## Evidence

All evidence prefix: `/Users/tinyserve/.hermes/cache/scratch/`.

- `compact-ui-red.xcresult`: expected failure, inline menu absent. `compact-calendar-red.log`: missing RollingWeek before implementation.
- `compact-final.xcresult`: full Release suite **89 methods / 97 parameter-expanded executions**, zero failures/skips/runtime warnings (77 unit/render + 12 UI).
- `compact-candidate.xcresult`: **80 methods / 88 parameter-expanded executions**, zero failures/skips/runtime warnings: all unit/render plus compact ordinary/XXXL/keyboard, menu/six-query/cache/relaunch/appearance and native pull UI tests. This follows the last selector foreground-style change; native Menu still tints its label blue in runtime, so neutral-label styling is not claimed.
- `compact-small-delivery.xcresult`: 2/2 Release UI methods on isolated iPhone SE 3, dark ordinary/XXXL, menus, palettes, shapes, persistence and keyboard. Final neutral selector color is the only subsequent presentation change.
- `compact-watch-final.log`: Watch Release BUILD SUCCEEDED, including widget. No Watch view/config changes.
- `compact-offline.log`: 23 offline CI contract/signing tests pass. `git diff --check` clean.

Calendar test exercises every preset, French locale calendar, Monday boundary, both Berlin DST transitions, next-day recomputation, unique dates and alignment with workout period. Controlled actual AnyRingViewModel test asserts exact query registration, same-value no-op, calendar-range starts, persisted period, config publication, obsolete ring and widget completion rejection and matching new-period cache. Actual UI period tap asserts exactly six additional synthetic reads. Existing privacy/endpoint/custom-name/workout/async generation tests remain green.

## Runtime screenshots and measurements

- Before: `compact-before-images/F9AA03E4-16A1-4925-8967-ECC5F3FF5FC2.png`.
- Full final UI: `compact-final-evidence/manifest.json` maps all screenshots to named test attachments.
- Final color-corrected candidate: `compact-candidate-images/manifest.json`.
- Dark small-phone: `compact-small-delivery-images/manifest.json`.

Measured actual 1206×2622 @3x captures using AppKit bitmap scan (`compact-measure.swift`), saturated green graph bounds before `[289,598,917,1226]`, after `[229,361,977,1109]`. Width **628 → 748 px**, **+120 px / 40 pt (+19.1%)**, square footprint +41.9%; graph starts **237 px / 79 pt higher**. Same fixture, same simulator. These are stroke bounds, not shadow or card bounds. Final label-color adjustment does not alter geometry.

Inspected with vision: baseline, ordinary 3/5-day, unified Appearance, XXXL French numeric formatting, keyboard, small dark and revised continuous range. Earlier visual review caught date digits splitting at XXXL and misleading individual outlined cells; fixed with a bounded date-strip type size (through XXXL, not accessibility XXXL), one-line dates, continuous range underline, and stacked menu label/value at accessibility sizes. Metrics retain full Dynamic Type and scroll normally.

## Independent release review

- Fresh origin/main still `c23364b2c0f7ad653271fe116fd614b7c287590d`; the retained seven-Swift-file candidate and screenshot `compact-candidate-images/DA3F4BD5-A1B5-4233-B875-CAC2B940BAAC.png` were inspected before any release action.
- Independent read-only code review found one introduced mismatch: the date strip could advance at midnight while readings retained the previous period. Fixed within the existing scoped views: minute ticks align with midnight and a changed calendar start-of-day refreshes the production model (including widgets), while ordinary minute ticks do not query HealthKit. Existing foreground refresh is retained.
- `compact-rollover-red.xcresult` reproduces missing midnight/timezone callbacks (three expected assertions); `compact-rollover-green.xcresult` passes five methods, including the actual hosted SwiftUI lifecycle, five-zone calendar arithmetic, and both SE dark ordinary/XXXL UI flows. Tests inject dates/calendars, not the machine clock. The host lifecycle test uses bounded readiness waits for loaded CI runners.
- Inline period UI verifies six additional synthetic reads; home/foreground verifies renewed queries. Five-day period, circle shape and Aurora palette survive cold relaunch. Nonincluded weekdays are dates marked Not included, never fabricated daily values or zero activity.
- Final independent reviewer verdict: **PASS**, no remaining critical introduced bugs/security/performance findings (`compact-release-review-final.txt`). Read-only reviewers did not run builds; execution evidence is separate.
- No provider/formula/goal/baseline/identity, Watch connectivity, widget implementation, project metadata, icon, signing script or workflow changes. Original dirty worktree hashes/status are recorded in `compact-original-before.json` and checked again after publication.

## Release verification

- Fresh local full Release suite after rollover fix: **91 methods / 99 parameter-expanded executions**, zero failures/skips/runtime warnings (`compact-release-final.xcresult`).
- Exact final source after two warning-only corrections (Binding setter closure and scene-backed test window): **81 methods / 89 expanded executions**, all unit/render tests plus both compact UI methods on dark iPhone SE; zero failures/skips/runtime warnings and no compiler warnings (`compact-release-exact.xcresult`). Full suite previously exercised all 12 UI methods; hosted CI independently tests final source before upload.
- Final Watch Release build **BUILD SUCCEEDED**, including Watch widget (`compact-release-watch.log`); 23 offline CI/signing checks pass (`compact-release-offline.log`). Shell syntax, shellcheck/actionlint and `git diff --check` clean.
- Read-only code-review PASS and real retained/fresh screenshots inspected. Evidence lives under the scratch prefix above, with exported small-phone attachments in `compact-release-small-images/`.

## Publication

**2.0 (37.1) uploaded successfully on 2026-11-16.** Release source `34142b2f3bfe42e3ba602cf81f522cc8095ce78d`; [run 43939623194](https://github.com/ptmt/anyring/actions/runs/43939623194), validation job `133553353875`, upload job `133575831719`, all success. Apple explicitly reported **Upload succeeded** and processing at `2026-11-16T20:11:53Z`, followed by **EXPORT SUCCEEDED**. All four original targets signed and all profiles validated; cleanup succeeded, no GitHub artifacts. Hosted complete Debug and separate Release suites passed. Push-only run `43939605661` succeeded without uploading.

Original worktree HEAD/status and all 13 dirty-file hashes preserved. Only this task's three regenerable DerivedData directories were removed after upload (1688162304 allocated file bytes); all xcresults, screenshots, summaries, reviews and CI logs retained. See `ci/RELEASE.md` and `compact-release-cleanup.json` for details. Apple processing completion/tester availability are not verified; no App Review submission.

## Limits

No physical iPhone/Watch/paired sync or live Health coverage tested. App stays English as requested; French locale verifies numeric/keyboard/calendar behavior, not a new localization. Small screens/XXXL require normal whole-page scrolling; all metrics are reachable. Date strip alone caps Dynamic Type to keep seven dates intact, with full spoken dates retained. Midnight/timezone lifecycle is tested by injected dates/calendar on the actual hosted view, not an overnight run or a real OS timezone-settings change. Existing Watch snapshot tests cover configuration publication/decoding, not physical delivery. No real Health samples used.
