# Saved-template selection — released 2.0 (47.1)

November 21, 2026. Base: `5773c6b20d5088c9ccfe071f798a6be1fd6be1e9`, verified against remote main before creating the isolated `fix/saved-template-selection` worktree. After the real preview and the owner's explicit publication approval, unchanged source `ffa4103dac3d30716a1f041d001abbed7e52bfcc` was uploaded as **2.0 (47.1)**. The released **45.3 / No data** behavior is preserved.

## Publication

[Run 44882710387](https://github.com/ptmt/anyring/actions/runs/44882710387), attempt 1, succeeded: validation **136781294719**, upload **136789344053**. All four original profiles validated and targets signed; archive and export succeeded. Apple explicitly reported **Uploaded package is processing.** and **Upload succeeded.** at **2026-11-21T08:36:31Z**. Signing credential cleanup succeeded; zero GitHub artifacts. Processing completion and tester availability remain unverified; no App Review submission.

Exactly one publish dispatch; no retries or source changes. Existing final xcresults below were re-read and all three changed-source SHA-256 hashes matched `source-receipt.json`; the local simulator matrix was reused, not rerun. Fresh 29 offline tests, ShellCheck, shell syntax, actionlint and diff checks passed. Hosted simulator build, unsigned Release archive, full Debug app/widget/navigation and targeted Release tests passed. Publication used a normal non-force push from the isolated worktree; original dirty main was never checked out or reset. No local simulator or new DerivedData was needed for publication; existing acceptance evidence is retained.

## Change

The active template now has a quiet neutral rounded fill and 1pt inset border around its **entire preview and name**. Every tile has the same 4pt padding. The conditional below-title checkmark is removed; the strip is top-aligned and selection does not animate geometry. Existing stable IDs, full-configuration equality, selected accessibility traits, confirmation/restore behavior and the **Save current** header are unchanged. Palette UI, ring renderer, goals, sources, formulas, periods, storage schema, four shipping bundle IDs and entitlements were not changed.

Only `TemplateView.swift` changes production presentation. `AppController.swift` adds an explicitly opted-in simulator-only synthetic fixture; `Tests_iOS.swift` adds native geometry and accessibility regressions. Geometry telemetry is non-layout and simulator/fixture-gated.

## Native RED → GREEN

The same native regression first failed against the original production presentation, before the highlight change. On the normal phone, the selected item's height changed **73.333 → 88.667pt**, and its preview/title moved **7.667pt** relative to its neighbors. The baseline Form row was **176.667pt**. Baseline screenshot and exact geometry are retained as `red.png` and `red-geometry.json`.

After the change, switching **swim → hrv/steps/hr → zones → swim**, including cold launches, produces **0pt maximum frame delta** across every captured item, preview, title and content frame on both phones, in both themes. The Form row and save-control frames also remain constant. Whole native button hit frames exceed 44pt.

| Geometry | Normal phone | Small phone |
| --- | ---: | ---: |
| Empty library Form row | 74pt | 74pt |
| Populated Form row | 169.333pt | 169.5pt |
| Selection-induced frame delta | 0pt | 0pt |

The populated strip is smaller, not taller. The normal baseline-to-candidate reduction is 7.333pt. Real screenshots reproduce the supplied squircle/Arctic, capsule/Sunset and hexagon/Candy designs using **synthetic configurations and mock readings**, not personal Health data.

## Final executed gates

Xcode 27.2 (27B52), Release, iOS 27.2. Exact final test sources; sequential existing devices, parallel testing disabled. All final bundles were read with `xcresulttool`; no failures, skips or reported runtime warnings:

| Result bundle | Passing test identities | Scope |
| --- | ---: | --- |
| `final-normal-light.xcresult` | 91/91 | 86 unit/widget/render identities plus five focused UI tests |
| `final-normal-dark.xcresult` | 2/2 | Geometry/three-way restore/cold launch and AX XXXL titles |
| `final-small-light.xcresult` | 5/5 | Same five focused UI tests |
| `final-small-dark.xcresult` | 2/2 | Geometry/three-way restore/cold launch and AX XXXL titles |

The five UI methods are `testSavedSelectionKeepsNativeGeometry`, `testSavedSelectionAccessibilityTitlesFit`, `testSavedConfigurationStripRestoresCompleteSettings`, `testDashboardDensityEmptyAndSavedRows` and `testDashboardDensityAccessibilityContent`. Existing save/name validation, change-source/goal/period/shape, complete restoration, cold launch, rename and delete-cancel/confirm flows passed. The final simulator settings were read back: all three synthetic saved records remain, and the entire current configuration equals saved **swim**. Only settings, not cached readings, are exported in `synthetic-restored-settings.json`.

Offline `python3 -m unittest discover -s ci/tests -v`: **29 passed**, including release IDs/entitlements and No data guards. `git diff --check` passed. No compiler warnings were found in the inspected build logs. Xcode's debugger-version diagnostic and the unsigned unit host's missing HealthKit-entitlement log remain simulator limitations, not physical-device Health authorization evidence.

Early accessibility test runs failed because the row was virtualized or fast native scroll gestures overshot the middle tile. The harness now scrolls to the actual row and uses bounded slow drags with a final hold; full-frame and text-fit assertions were retained. Those failed receipts remain in scratch; the table above is the fresh coherent final matrix, not a mixture of partial reruns.

## Preview and receipts

All PNGs below are unmodified, inspected, real native runtime captures under `docs/evidence/template-selection/`:

- Normal: `final-normal-light.png`, `final-normal-dark.png`.
- Small: `final-small-light.png`, `final-small-dark.png`.
- AX XXXL: the four matching `*-accessibility.png` files; each selected tile/name and the save header fit. Neighboring carousel content can naturally scroll outside its viewport.
- `*-summary.json`, `*-geometry.json`, `density.json`, `source-receipt.json`, and the synthetic settings receipt retain machine-readable evidence.

Full logs, xcresults, all three selection screenshots and exported attachments: `/Users/tinyserve/.hermes/cache/scratch/anyring-selection/`. `run_acceptance.py` records the exact sequential commands. Builds use `AnyRing/AnyRing.xcodeproj`, scheme `AnyRing (iOS)`, `-configuration Release`, `-parallel-testing-enabled NO`, `-maximum-concurrent-test-simulator-destinations 1`, `CODE_SIGNING_ALLOWED=NO ENABLE_TESTABILITY=YES ONLY_ACTIVE_ARCH=YES` and explicit `-only-testing` filters.

Borrowed devices `93E1113F-6736-4CCB-827D-0E2F1C3876EA` and `56A70197-59DE-4410-9E76-25272244E9C8` were restored to dark/light appearance respectively and read back **Shutdown** during local acceptance. No simulator was created, cloned, erased or deleted locally. Other worktrees were not touched. Original `/Users/tinyserve/Projects/anyring` HEAD, index hash, exact status and all 13 dirty-file hashes were verified unchanged before and after publication. Physical installation and real Health/Watch behavior are not established by these synthetic tests or the upload.
