# Metric information — published 2.0 (49.1)

November 21, 2026. Approved source **1cdf725e97078ac3d52c6498b390858c3e4c8197**, from isolated worktree `/Users/tinyserve/Projects/anyring-metric-info`, branch `fix/metric-info`, based on freshly fetched `origin/main` **3badeda1225b765185b9e4c17a06adbca45b13b4**. Published unchanged after the owner's approval of the native preview; supersedes **ffa4103dac3d30716a1f041d001abbed7e52bfcc / 2.0 (47.1)**.

## Publication

One normal non-force push, remote SHA read-back, then exactly one `testflight.yml` dispatch on `main` with `publish=true`. [Run 44893826913](https://github.com/ptmt/anyring/actions/runs/44893826913), attempt 1, succeeded: hosted validation **136815129093**, upload **136822703009**. Full hosted Debug app/widget/navigation and targeted Release gates, simulator build and unsigned archive passed. All four original profiles validated and all four targets signed; **ARCHIVE SUCCEEDED**, **Upload succeeded.** / **Uploaded package is processing.** at **2026-11-21T10:55:20Z**, then **EXPORT SUCCEEDED**. Logged build **49.1**, marketing **2.0** retained. Credential cleanup succeeded; GitHub artifacts count **0**. No retry, duplicate upload or App Review submission. Apple processing completion and tester availability are not verified.

Before publication, all seven changed-source SHA-256 values matched the existing source receipt; all six actual xcresults were re-read (**112 passing executions**) without repeating simulator work. Fresh offline discovery passed **29/29**, shell syntax and diff checks passed. No local simulator/device mutation or new DerivedData was needed. Concise hosted receipts: `~/.hermes/cache/scratch/anyring-metric-info/publication-receipt.json`.

## Scope

Only the iOS overview's gray diagnostic text moves behind an always-present native information button. The colored bullet, metric name, current reading, configured target and unit remain visible. Each information button has a constant **44 × 44pt** hit region, its own metric-specific accessibility label and a native sheet with Done. The sheet observes the selected model directly and displays current/error/loading state, source, period, direction and an existing baseline when applicable. No last-updated date is invented: the individual `RingViewModel` does not expose a reading timestamp. The existing Apple Health link is available inside a no-samples sheet.

The conditional all-empty dashboard explanation also leaves the interactive overview; otherwise it would continue resizing the whole card even after removing each metric's paragraph. Noninteractive shared consumers retain their existing fallback diagnostics. The information presentation is explicitly opted into by iOS `MainScreen`; widgets and Watch do not receive inert buttons or a redesigned interface.

Ordinary text retains its inline `current / target unit` formatting and font sizes. At accessibility sizes, current and target use separate semantic lines: a shorter em dash can no longer pull the target up a line. Nothing reserves an empty error paragraph, clips metric text or shrinks its font. Only the decorative info symbol's scaling is capped to remain compact inside its constant hit region.

Production Health queries, authorization, refresh/cache behavior, unknown-versus-zero presentation, formulas, goals, renderer, source identities, storage, saved-template selection and **No data** widget wording are unchanged. Opening/closing the sheet adds no Health reads. `AccessibilityFocusState` returns assistive focus to the originating button on dismissal; native tests verify the correct button remains available and hittable, not actual spoken VoiceOver traversal.

## Native RED → GREEN

Tests and simulator-only state controls were added before production presentation changes. Against the original presentation, the real Release UI regression failed: the three synthetic density-fixture rows expanded with their status paragraphs, and the dashboard/save-row boundary moved **224pt**. The info-button test failed because no such control existed. Original receipts: `red-summary.json`, `red-geometry.json`, `red-error.png`.

An early small-phone maximum-Dynamic-Type run then caught a **58pt** reflow caused solely by changing a two-digit reading to an em dash. The semantic current/target split fixed that failure without reducing text size. That failed run is retained at `small-preview.xcresult` in scratch.

Final fixtures use synthetic Swim, Flights Climbed and Heart-rate configurations; no personal Health data is read. Ready → error → loading → ready produces **0pt vertical delta** for all three metric text bounds, and **0pt full-frame delta** for the enclosing dashboard Form cell and neighboring saved-configuration cell, on both phones in both themes. AX text-content widths naturally differ between a number and an em dash; the evidence does not misrepresent those widths as whole-row layout bounds. Maximum AX tests also scroll each complete metric into bounds before comparing its position/height and opening its sheet.

| Final Release result | Passed | Scope |
| --- | ---: | --- |
| `final-normal-light.xcresult` | 94/94 | 86 existing unit/widget/render test identities + 8 UI tests |
| `final-normal-dark.xcresult` | 4/4 | Metric transitions, all three live sheets, AX XXXL, clean preview |
| `final-small-light.xcresult` | 8/8 | Same 8 UI tests |
| `final-small-dark.xcresult` | 4/4 | Same 4 metric UI tests |

**110 passing executions** in that matrix, plus **2/2** supplemental executions of `testSavedSelectionAccessibilityTitlesFit` (normal and small, light, same final source) in `selection-ax-normal.xcresult` and `selection-ax-small.xcresult`. No failures/skips/runtime warnings in these final xcresult summaries. All final runs use the same source receipt. The four existing shipping targets (phone, phone widget, Watch, Watch widget) are in the successful simulator build graph; no new target or bundle identifier was added.

The four metric UI tests verify status transitions and geometry; the correct title, existing error, source and period for every metric; live sheet status updates; 44pt targets; dismissal; unchanged read-count/cache telemetry across sheet use; maximum accessibility size; and clean screenshots. The other four UI tests cover empty/saved density, maximum-size dashboard content, complete save/change/restore/cold-launch configuration behavior and three-way saved-template selection geometry. The selected-template highlight remains unchanged.

Offline tests: **29/29**, both clean baseline and candidate. `git diff --check`, conflict-marker/security scan and source-hash verification passed. Xcode **27.2 (27B52)**, iOS **27.2**, Release, parallel simulator testing disabled. One build diagnostic says App Intents metadata extraction was skipped because there is no AppIntents dependency. The known debugger-version lookup and unsigned simulator HealthKit-entitlement logs do not establish physical-device Health authorization.

## Preview and evidence

All PNGs are unmodified native screenshots. Under `docs/evidence/metric-info/`:

- `final-normal-light-overview.png` and `final-normal-light-info.png`: clean overview and Swim sheet for the user preview.
- Equivalent normal-dark/small-light/small-dark overview and info images.
- Corresponding `*-ax.png` and `*-ax-info.png`: maximum Dynamic Type captures. Diagnostic test-control overlays are visibly synthetic and excluded from device builds and clean previews.
- `*-geometry.json`, `*-summary.json` and `source-receipt.json`: exact captured frames, parsed test results and changed-source hashes.

Full logs, xcresults, all three sheet/AX captures, negative runs and the sequential runner are retained at `/Users/tinyserve/.hermes/cache/scratch/anyring-metric-info/`. `run_acceptance.py` records the explicit commands. Builds use `AnyRing/AnyRing.xcodeproj`, scheme `AnyRing (iOS)`, `-configuration Release`, explicit destinations, `-parallel-testing-enabled NO`, `-maximum-concurrent-test-simulator-destinations 1`, `CODE_SIGNING_ALLOWED=NO ENABLE_TESTABILITY=YES ONLY_ACTIVE_ARCH=YES` and named test filters.

Borrowed devices `93E1113F-6736-4CCB-827D-0E2F1C3876EA` and `56A70197-59DE-4410-9E76-25272244E9C8` were reused serially, restored to dark/light respectively and read back **Shutdown**. No device was created, cloned, erased or deleted. Original dirty `/Users/tinyserve/Projects/anyring` retains HEAD `2552ee52e2339f00828e82615aaa63903af4cede`, index SHA-256 `9ee10522452e120287eb650fd65f92e97b075cf26f6d34beafe6594a368e1472` and the same exact 13-entry status. All 13 dirty-file SHA-256 hashes, exact NUL-delimited status, index and HEAD also match the preserved pre-task release snapshot at `/Users/tinyserve/.hermes/cache/scratch/anyring-selection/publish-original-snapshot.json`. The source worktree remains clean; KeineMagie project files were not touched.

The local UI/build acceptance above uses explicitly synthetic data, not real Health permissions or physical Watch behavior. Publication is separately verified above. The local app artifact is `build/Build/Products/Release-iphonesimulator/AnyProgress.app` beneath the scratch directory above.
