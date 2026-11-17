# Dashboard density — compact labels pending native preview

## Latest user requirement: inline current / configured target

The user approved the concept “можно даже без больше или равно просто таргет /80 или /15000”: no visible `Goal`, ≥/≤ or baseline row in the **overview**. The number 80 was an example, **not** authorization to change the heart-rate goal from 42 to its starting baseline of 80.

- Keep the custom metric name above the value and its colored marker. Show the actual current reading followed inline by muted `/ target`, with the shared unit once: `110 / 100 ms`, locale-formatted `5,100 / 15,000 steps`, `55 / 42 bpm` for the existing synthetic density fixture. No reading or saved setting is rewritten.
- `RingViewModel.targetText` reuses the existing finite-value/locale-aware 0…1 decimal formatter and the existing reversed-goal choice. Mean steps and other decimals are **not** newly rounded to integers. Workout zones 2–3 / 4–5 use the same overview renderer and their configured minute goal.
- Direction, comparison, configured target, applicable baseline and errors remain in the overview's full accessibility label. Settings retain their goal/baseline controls. Names, source, aggregation, formulas, Health queries, cache, Watch synchronization, persistence, renderer/glow and all saved configuration features are untouched.
- Only `RingDashboardLegend` changes visually. Watch uses `RingMetricView`, whose typography, progress bar and explanatory rows remain unchanged. Existing `goalText` output remains unchanged. The overview keeps Dynamic Type, a wrapping single Text and intrinsic vertical sizing; no forced single line, font-size cap or shrink factor is added.
- Neutral Period/week dots and the fixed intrinsic empty-library Save row remain unchanged.

### Current local verification (not pixel acceptance)

Started from clean `bf70afe7b66f864b5e99ec9c17e3563789cec8d5` in this isolated candidate. Two new lightweight tests failed first (missing target property and old visible Goal/baseline rows), then passed after implementation. `python3 -m unittest discover -s ci/tests -v`: **28/28 passed**. The test executes the actual presentation-property slice with Foundation in `en_US`, `fr_FR`, `ru_RU` and `ar_EG`, checking decimal precision, Unicode units/digits/grouping, configured target versus baseline, reverse/higher direction and loading/error accessibility. This is a presentation harness with input adapters, **not** execution of HealthKit or the full model. Swift frontend parsing and `git diff --check` pass.

Prepared native `compactOverviewKeepsConfiguredGoalAndBaselineDistinct` coverage for the real model (55 / 42, baseline 80, custom Unicode name, both workout metrics). Strengthened the existing accessibility XXXL test to assert reverse target 42 and baseline 80 separately. These native tests have **not** run for this revision. Existing French/large-type and density screenshot tests are ready for the later serial native run; actual wrapping, RTL layout and full-platform typechecking remain unverified.

**No Xcode build, simulator boot or screenshot was attempted:** KeineMagie integrator `sa-0-374f8e76` owns the sole heavy slot until the parent grants it. After that handoff, capture the actual updated Release overview (existing `--dashboard-density-fixture`, `testDashboardDensityEmptyAndSavedRows`) and inspect the large-type/locale cases. Show the new real capture to the user before any publication. The prior screenshots/measurements below predate the compact-label change and are **not proof of this revision**. No push, release or edit to the original dirty worktree is authorized.

## Earlier density proof (before inline labels)

## Scope and provenance

- Candidate presentation: `3310bd18708ab1133179fa2ccdbe9c970185e6b9`, isolated worktree `/Users/tinyserve/Projects/anyring-dashboard-density`.
- Released baseline: `b916eaa7909f1929c6cafe213e419cda669a2ad5`, release documentation `5e7d424`, version 41.2. Baseline was archived into task-owned scratch and only the synthetic fixture/UI test transplanted for the initial comparison.
- Both run the actual production Form in **Release**, iPhone 13 / iOS 27.2, 390 × 844 points. Synthetic HRV / Step count / Heart-rate, goals 100 / 15,000 / 42, HR baseline 80, three days and squircle. Existing synthetic readings/default colors, not private Health data. The library starts genuinely empty through existing simulator-only persistence reset; no fake Form or fabricated screenshot.
- No provider, formula, aggregation, persistence codec, cache fence, midnight behavior, renderer, glow, identifier, Watch/widget production code changes. No push or deployment. Parent must show actual screenshots to user before publication.

## Reproduction and causal investigation

The native baseline reproduces the supplied screenshot's oversized empty Saved templates row. `baseline-red.xcresult`: **1 executed test, 1 expected regression failure** at the ≤80pt empty-row assertion; measured **204.333pt**. Populated row was **307pt**. The empty branch does not instantiate a carousel.

**Correction to the earlier hypothesis:** lack of intrinsic sizing on the ViewThatFits header was not established as the cause. Actual one-variable native probes retained the 204.333pt failure when adding header-only intrinsic sizing, outer-only intrinsic sizing, plain style alone, moving the min-height into the label, explicitly selecting title-and-icon with that label, or replacing ViewThatFits with its HStack. These are retained failed diagnostic probes, not shipped fixes.

The decisive differential probe replaces **only the saveButton implementation** with the candidate control, keeping the entire baseline ViewThatFits/header/carousel and old week unchanged. `root-savebutton-only.xcresult`: **1/1 passed**; empty **74pt**, filled **176.667pt**, save/header control **44pt**. This isolates the oversized layout to the old native save-control composition in its Form context, not an empty carousel or the week. It does not identify a private SwiftUI internal algorithm or prove a single modifier independently sufficient. The candidate explicitly composes a title-and-icon Label, minimum 44pt label target, plain neutral button, and intrinsic layout boundaries. Its empty path is one “Save current setup” action; populated path preserves the accessible header and actual thumbnails.

Week inclusion uses neutral dots rather than rectangular selected cells/underline. Names, complete values/goals/baseline, left rings/right legend, Today, period menu and accessible date/value semantics remain.

## Actual point measurements

All CGRect values are XCTest runtime attachments, not estimates from JPEG pixels.

| 390pt ordinary-size state | Released baseline | Candidate |
|---|---:|---:|
| Dashboard row x,y,w,h | 16,82,358,370 | 16,82,358,375 |
| Empty saved row x,y,w,h | 16,452,358,204.333 | 16,457,358,74 |
| Empty card union x,y,w,h | 16,82,358,574.333 | 16,82,358,449 |
| Save/header control height | 174.333 | 44 (label minimum; empty Form AX button wraps the full 74pt cell) |
| Populated saved row height | 307 | 176.667 |
| Empty footer cell reduction | — | 130.333pt |
| Combined card reduction | — | 125.333pt |

The native row contributes 30pt beyond the candidate's 44pt label target. No magic negative padding/fixed carousel height was used. Appearance is visible on the first ordinary screen. Small iPhone SE (3rd generation), 375 × 667pt: dashboard `(16,55,343,376.5)`, empty row `(16,431.5,343,74)`, populated row 177pt. All three complete readings/goals/baseline remain visible at ordinary size; accessibility XXXL scrolls naturally.

## Verification ledger

Evidence root: `/Users/tinyserve/.hermes/cache/scratch/dashboard-density-proof/`.

| Result bundle | Executed / passed | Scope |
|---|---:|---|
| `baseline-red.xcresult` | 1 / 0 | Real baseline targeted RED |
| `root-savebutton-only.xcresult` | 1 / 1 | Control-only causal differential |
| `candidate-light.xcresult` | 86 / 86 | 83 unit/widget test identities + 3 UI tests: density lifecycle, accessibility, full saved restoration/cold relaunch |
| `candidate-dark.xcresult` | 4 / 4 | Density lifecycle, accessibility, neutral rendered period/menu, period relaunch |
| `candidate-small-retry.xcresult` | 2 / 2 | Small ordinary lifecycle + strengthened metric visibility at accessibility XXXL |
| `final-light.xcresult` | 2 / 2 | Ordinary density and strengthened complete metric visibility |
| `final-dark.xcresult` | 1 / 1 | Strengthened complete metric visibility |
| `ax-light.xcresult` | 1 / 1 | Final complete metric AND footer visibility, normal light XXXL |
| `ax-dark.xcresult` | 1 / 1 | Same, normal dark XXXL |
| `ax-small.xcresult` | 1 / 1 | Same, small phone light XXXL |

The first combined result reports 86 test identities and 94 parameter-expanded device executions; these are different counts, not missing tests. No skips/failures in candidate rows above. Relevant tests exercise save, selected thumbnail, rename, canceled/confirmed deletion and return to empty, complete source/goal/baseline/name/shape/period restoration, unsaved-change confirmation and cold relaunch. Unit suite includes period/cache/query/midnight/widget regressions. Python CI: **26/26 passed**. `git diff --check` passes.

Inspection caught a test weakness: `isHittable` can be true when a metric/footer is only partly visible. UI tests now require full vertical bounds within the viewport and use bounded short drags before screenshots, rather than equating existence/hittability with complete visual evidence. Final `ax-*` reruns record the fully visible footer too. AX labels/targets were exercised; actual VoiceOver spoken focus traversal was not independently performed.

Initial Release build needed `ENABLE_TESTABILITY=YES` for the existing @testable unit target; initial build failure is not counted as a test run. Small-device first attempt exceeded the tool's 420-second wall timeout and left an incomplete result bundle; a bounded retry passed 2/2. No weakened geometry assertion or fabricated output was substituted.

## User-preview PNGs

Durable full-resolution, unedited native captures:

- Before: `/Users/tinyserve/.hermes/cache/documents/dashboard-density-proof/before/Density empty library synthetic.png`
- After light: `/Users/tinyserve/.hermes/cache/documents/dashboard-density-proof/final-light/Density empty library synthetic.png`
- After dark: `/Users/tinyserve/.hermes/cache/documents/dashboard-density-proof/dark/Density empty library synthetic.png`
- Populated: `/Users/tinyserve/.hermes/cache/documents/dashboard-density-proof/final-light/Density saved library synthetic.png`
- Small: `/Users/tinyserve/.hermes/cache/documents/dashboard-density-proof/small/Density empty library synthetic.png`
- Accessibility complete metric examples: `final-light/`, `final-dark/`, `small/` under that same durable directory; final complete-footer captures in `ax-light/`, `ax-dark/`, `ax-small/`.

These use synthetic provider values/default appearance, intentionally not the user's personal readings or Sunset palette. Visual approval is still required; do not describe this as released.

## Resource ownership and preservation

A single task-owned simulator runs at a time, no Xcode clones, parallel testing disabled, two compiler jobs, one shared 658MB DerivedData directory for serial baseline/candidate builds. Exact owned IDs: iPhone 13 `0745A7DD-E04E-4F4B-9D57-78EC5068EEC1`; SE `FCDE53E2-44D9-4021-9AEC-8A26C630865B`. Restore light appearance and shut down owned devices before returning the heavy slot. Do not shut down/delete other tasks' existing booted devices or touch KeineMagie worktrees.

Original `/Users/tinyserve/Projects/anyring` snapshot at `dashboard-density-original.json`: all **13 dirty file SHA-256 hashes**, HEAD and index hash rechecked unchanged. Only this isolated worktree's UI-test visibility assertions and this proof document were changed after candidate 3310bd1. Task-owned diagnostic source variants, logs, xcresults and exported screenshots remain separate from production source.

After exporting/inspecting evidence, both owned devices were verified Shutdown, then only these two regenerable synthetic devices and the task-owned 658MB DerivedData were deleted. Read-back device lists retained in `devices-before-cleanup.json` / `devices-after-cleanup.json`; no other simulator was modified. Final filesystem free space: **17GiB**. Heavy simulator slot is released. Logs/xcresults/source probes and durable full PNGs remain. Offline owned-store inspection before cleanup confirmed stored Config.v3 with absent saved-library key (production restores `[]`) on the normal fixture and explicit saved `[]` after deletion on the small fixture; only nonsensitive empty-state receipts were retained.
