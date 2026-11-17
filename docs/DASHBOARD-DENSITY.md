# Dashboard density — native candidate verified, visual approval pending

## Latest: subtle background behind the included calendar range

The user's supplied crop shows **November 15, 16 and 17: three included days**. On clean base `1fde467fb0f4a29b80155923d1c02df788da41e2`, the only production change adds one continuous rounded background behind the last N calendar cells. It does not shade all seven unless seven days are selected. The existing quiet dots, full-date/Included accessibility, Today, inline current/configured-target labels and compact Save row remain unchanged. No underline, internal rounded seams, extra height, blue tint, formula/query/persistence/cache/Watch/identifier changes.

- `TrackingWeekView` uses a background-only GeometryReader and one continuous 10pt RoundedRectangle, logical trailing alignment, with a clamped 1…7 fraction of the existing row width. Light fill is neutral 0.94, dark graphite 0.18. The background is accessibility-hidden and cannot propose a new foreground height.
- Tested production file SHA-256 (`AnyRing/Shared/Views/RingDashboard.swift`): `e5ab5127faa4bef3f7429fe87420cb394b8308a49b2870b06cc741c09e1ff8d5`.
- Final UI-test file SHA-256: `8e30d83b4868c540b09246edabe955c65888bd919664c3c88f127261b318be2b`.

### Native verification — November 17, 2026

Xcode 27.2 / iOS 27.2, actual Release app, iPhone 13 (390×844pt; 1170×2532 native PNG), ad-hoc signing, two compiler jobs, parallel testing disabled. One task-owned simulator `BE166CC8-6579-4602-99FC-4CADA212D38B`, serial runs only. Explicit synthetic fixtures; no real Health records or provider calls.

Evidence: `/Users/tinyserve/.hermes/cache/scratch/week-range-proof/`.

| Result | Passed / executed identities | Result and scope |
|---|---:|---|
| `red.xcresult` | 0 / 1 | Expected native RED: all five presets have zero background/fill difference on the original source |
| `light.xcresult` | 87 / 88 | All 84 unit/widget identities and three existing UI tests passed; new pixel test exposed an AX-frame assumption, corrected below. 95/96 parameter-expanded executions. |
| `final-light.xcresult` | 3 / 3 | All 1/2/3/5/7 presets, empty/populated library lifecycle, neutral pixels/menu, normal and maximum accessibility text |
| `final-dark.xcresult` | 4 / 4 | Same, plus complete individual metric/footer viewport assertions at accessibility XXXL |

All final runs have zero failures/skips. The mixed intermediate run is **not** represented as a wholly passing suite. Its source is production-identical to final: SwiftUI exposes text-content AX bounds, excluding equal-width cells and vertical padding. The test now reconstructs the rendered grid from the native Period bounds and existing 5pt vertical padding; it checks solid background pixels, unselected cells, uninterrupted internal seams, four rounded outer corners, complete content containment, Included/Today values and constant geometry. No production correction or weakened background assertion was needed after this instrumentation fix.

Final ordinary week grid: `(36,311,318,67.6667)` pt for every preset in both themes. Dashboard remains `(16,82,358,319.6667)`; empty saved row remains **74pt**, populated **176.6667pt**, populated Save **44pt**. Appearance remains visible initially. The 204pt blank row has not returned. Maximum-text screenshots show the complete Today label inside the selected range; the pre-existing calendar-only Dynamic Type limit is unchanged.

Measured solid RGB grayscale values: light range **240** on card **255**, dark **46** on **28**. Primary labels are 0/255, secondary/dots 102/166. Computed contrast against the selected fill: primary **18.43:1 / 13.58:1**, secondary **5.04:1 / 5.58:1** (light/dark). Actual rendered neutral-pixel checks pass. These measurements are not a claim that a subtle decorative fill alone meets a non-text contrast threshold: dots and complete AX state are retained.

Python CI: **28/28 passed**; `git diff --check` passed. Existing native tests also verified save/rename/cancel+confirm delete, complete settings restore/cold relaunch, configured goal versus baseline, midnight/calendar/cache/provider/widget regressions. Actual VoiceOver spoken traversal and a fresh small-phone run were not performed in this background-only change.

### Actual final PNGs for the parent to share

Under `/Users/tinyserve/.hermes/cache/documents/week-range-proof/`, in both `final-light/` and `final-dark/`:

- `Included range 3 days synthetic.png` — full unedited native screen.
- `included-3-crop.png` — exact native-pixel crop of 15/16/17; no resize or repainting.
- `week-crop.png` — full seven-day strip crop, showing the unselected cells too.
- `Included range 1 days synthetic.png`, `Included range 2 days synthetic.png`, `Included range 5 days synthetic.png`, `Included range 7 days synthetic.png` — all other presets.
- `Neutral period UICTContentSizeCategoryAccessibilityXXXL synthetic.png` — maximum Dynamic Type calendar/Today evidence.

Final light/dark full screens, three-day crop and maximum-text screens were visually inspected. Synthetic readings/default palette, not the user's personal data. **Native candidate only; no push, upload or release. Parent must show the actual PNGs for approval.**

Resource/preservation read-back: the original `/Users/tinyserve/Projects/anyring` retains all **13 dirty file hashes**, exact HEAD, index and status (`original-before.json` / `original-after.json`). Other workers' simulators and KeineMagie worktrees were untouched. The owned device was restored to light, verified Shutdown and deleted; its absence was read back. Only the task-owned 685MB DerivedData and duplicate intermediate attachment exports were removed. All result bundles, logs, summaries and final native PNGs remain. The heavy simulator slot is released.

## Earlier: inline current / configured target

The user approved the concept “можно даже без больше или равно просто таргет /80 или /15000”: no visible `Goal`, ≥/≤ or baseline row in the **overview**. The number 80 was an example, **not** authorization to change the heart-rate goal from 42 to its starting baseline of 80.

- Keep the custom metric name above the value and its colored marker. Show the actual current reading followed inline by muted `/ target`, with the shared unit once: `110 / 100 ms`, locale-formatted `5,100 / 15,000 steps`, `55 / 42 bpm` for the existing synthetic density fixture. No reading or saved setting is rewritten.
- `RingViewModel.targetText` reuses the existing finite-value/locale-aware 0…1 decimal formatter and the existing reversed-goal choice. Mean steps and other decimals are **not** newly rounded to integers. Workout zones 2–3 / 4–5 use the same overview renderer and their configured minute goal.
- Direction, comparison, configured target, applicable baseline and errors remain in the overview's full accessibility label. Settings retain their goal/baseline controls. Names, source, aggregation, formulas, Health queries, cache, Watch synchronization, persistence, renderer/glow and all saved configuration features are untouched.
- Compact value presentation changes in `RingDashboardLegend`, with the native-verified ideal-width correction in its parent layout described below. Watch uses `RingMetricView`, whose typography, progress bar and explanatory rows remain unchanged. Existing `goalText` output remains unchanged. The overview keeps Dynamic Type, a wrapping single Text and intrinsic vertical sizing; no forced single line, font-size cap or shrink factor is added.
- Neutral Period/week dots and the fixed intrinsic empty-library Save row remain unchanged.

### Final native verification — November 17, 2026

Started this acceptance run from clean `ad8279a16b38d59ddbedcb4e64d59b36a397c00f` (includes density `bf70afe`). Xcode 27.2 / iOS 27.2, actual **Release** app and tests, ad-hoc simulator signing, `ENABLE_TESTABILITY=YES`, two compiler jobs, parallel testing disabled. Only explicit simulator synthetic fixtures were used; no real Health data.

**One real small-phone regression was found and fixed.** At 375pt the new inline value's ideal width made `ViewThatFits` choose the stacked overview, growing the dashboard to 506.5pt and hiding Appearance. `small.xcresult` executed 2 tests: accessibility passed, ordinary density failed its existing first-screen Appearance assertion. The only production correction is `legend.frame(minWidth: 140, idealWidth: 140)` in `RingDashboard.swift`: the value wraps before the existing layout falls back to stacking. No type shrinking, goal/formula changes or weakened assertions. `small-fixed.xcresult` then passed 2/2; normal light/dark were rerun on this corrected source.

Evidence root: `/Users/tinyserve/.hermes/cache/scratch/compact-label-proof/`.

| Final result bundle | Test identities passed / executed | Parameter-expanded device executions | Scope |
|---|---:|---:|---|
| `final-light.xcresult` | 88 / 88 | 96 | Entire unit/widget suite (84 identities), four UI tests: density lifecycle, XXXL, French normal/XXXL + keyboard, full configuration restoration/cold relaunch |
| `final-dark.xcresult` | 2 / 2 | 2 | Ordinary empty/populated lifecycle and complete XXXL metric/footer visibility |
| `small-fixed.xcresult` | 2 / 2 | 2 | SE 375×667pt ordinary empty/populated lifecycle and complete XXXL metric/footer visibility |

All final rows have zero failures/skips. The real-model `compactOverviewKeepsConfiguredGoalAndBaselineDistinct` executes in the full suite: target 42 remains distinct from baseline 80, including Unicode custom name and workout minute targets. Native accessibility tests retain Goal/direction/baseline semantics while screenshots show none of that extra overview chrome. Save, rename, cancel/confirm delete, restore and relaunch remain exercised. Normal light/dark captures show `110 / 100 ms`, `5,100 / 15,000 steps`, `55 / 42 bpm` with muted suffix and one unit. At 375pt the steps suffix wraps cleanly; XXXL stacks naturally and scrolls, with complete per-metric/footer viewport assertions.

`python3 -m unittest discover -s ci/tests -q`: **28/28 passed again after the fix**. Its actual Foundation presentation slice covers `en_US`, `fr_FR`, `ru_RU`, `ar_EG`, decimal precision, Unicode/grouping, reverse target/baseline and pending/error accessibility. Native French normal/XXXL runs cover layout and locale grouping, not full French app translation. Arabic RTL native pixels and actual VoiceOver spoken focus traversal remain unverified. `git diff --check` passes.

#### Final runtime bounds and actual pixels

CGRects below are XCTest attachments, not inferred source dimensions:

| Ordinary state | iPhone 13 light and dark | iPhone SE |
|---|---|---|
| Dashboard x,y,w,h (pt) | 16,82,358,319.667 | 16,55,343,330.5 |
| Empty saved row x,y,w,h (pt) | 16,401.667,358,74 | 16,385.5,343,74 |
| Populated saved row height (pt) | 176.667 | 177 |
| Populated Save control height (pt) | 44 | 44 |

The empty AX button wraps its 74pt Form cell; the label's minimum target remains 44pt. The previous 204.333pt empty-row regression has not returned. Appearance is visible on the first ordinary screen on both sizes. Pixel-column inspection of the actual full PNGs (`pixel-column-proof.json`) finds the normal card's fill beginning at y=246 and ending at y=1427 exclusive in **both** light and dark (1170×2532 PNG), and small card y=110…919 exclusive (750×1334 PNG). Text/separator holes are retained in the recorded runs, not painted over.

#### Send these actual final PNGs for user approval

Under `/Users/tinyserve/.hermes/cache/documents/compact-label-proof/`:

- `final-light/Density empty library synthetic.png`
- `final-dark/Density empty library synthetic.png`
- `final-light/Density saved library synthetic.png`
- `small/Density empty library synthetic.png`
- `final-dark/Density accessibility metric 2 synthetic.png`
- `small/Density accessibility metric 1 synthetic.png`
- `small/Density accessibility empty footer synthetic.png`

Full-resolution unedited native attachments, visually inspected. Synthetic values/default colors, not the user's personal Health records or palette. **Parent must send the screenshots; user visual approval still gates publication. No push or deploy.** Earlier `light-retry`/`dark` bundles precede the small-layout correction and are retained as intermediate evidence only.

Initial foreground build exceeded the tool's 420-second wall limit and was interrupted; it is not counted as acceptance. A background bounded retry compiled and passed. Serial fresh-device startup was slow but final results are complete. Only task-created devices were booted, one at a time; each was shut down, read back as Shutdown, and deleted to avoid disk accumulation. Owned UDIDs: `0BCC07E4-CC71-48A1-9412-B5960175FFA0`, `ED23E644-C2B3-4E82-8E28-E5C11975B278`, `653700FB-C3EE-433B-BF60-60B15BFF4D7F`. Other booted devices and KeineMagie worktrees were untouched. Original dirty worktree's 13 file hashes, HEAD and index rechecked unchanged. Only the layout fix and this document are changed in the candidate; no goal/baseline/provider/cache/persistence/Watch code changes.

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
