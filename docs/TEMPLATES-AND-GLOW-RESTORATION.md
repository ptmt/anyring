# Saved configurations, compact legend, and glow investigation

## Scope and provenance

Isolated worktree `/Users/tinyserve/Projects/anyring-templates-glow`, branch `fix/templates-glow-restoration`, based on verified `origin/main` `7b77fad87a0afda4c362eea628ba1c2820d42515`. Its app-source parent is `34142b2f3bfe42e3ba602cf81f522cc8095ce78d` (37.1). Original `/Users/tinyserve/Projects/anyring` had 13 dirty entries; only relevant diff/history was read. No original files, other worktrees, project identifiers, capabilities, release numbers or icon assets were changed during candidate implementation. Subsequently released as **2.0 (41.2)** from `b916eaa7909f1929c6cafe213e419cda669a2ad5` (production source unchanged from `83b7da7`); Apple upload succeeded **2026-11-17T07:43:05Z**. See `ci/RELEASE.md` for exact run/jobs and limits.

## What history actually establishes

- `77771e8` has the screenshot-era horizontal `TemplatesView` directly below `RingDashboard`. Its six hard-coded `RingWrapper<RingSnapshot>` items contain **only progress previews and appearance**. `RingViewModel.updateFromSnapshot` changes appearance, not sources/goals/period. `UserDefaultsConfigurationPersistence` holds one complete active `Config.v3`, not a named library.
- `023399c8943bb8b0b07263204ccf9ca0b48cf169` (October 12, 2026, “Rewrite and modernize”) moved that carousel to a separate Color Palettes section and replaced the horizontal graph/legend with a vertical graph/metrics layout. This is the identifiable loss of the old near-graph row and right-hand legend, **not evidence of deleted saved source configurations**.
- `48da9cbdfc6cdd33a6e1b4f8f0e523d6dcfabfc2` (November 13, 2026) introduced 18 named appearance palettes and the Canvas renderer. `34142b2` grouped palettes/shape under Appearance. All 18 remain intact here.
- `git log --all` searches for template/preset/saved-config storage and the original dirty model/editor diff found no separate historical full-configuration library. Therefore this candidate does not invent legacy template IDs, guess storage keys, or manufacture replacement “recovered” presets. If another released branch/build stored named templates, its actual fixture/key is needed before claiming that library has been recovered.
- Active settings already retained sources, exact HealthKit identifiers, units, aggregation, min/max/baseline, direction, custom names, workout metrics, period, shape, colors, gradient and glow. Their existing `AnyRingConfig`/`Config.v3` and revisioned snapshot codecs are reused without changes to decoding/migration.

## Candidate behavior

An additive `SavedConfigurations.v1` library stores complete `AnyRingConfig` values plus a stable UUID/name. Saving is explicit; it does not modify the active legacy configuration. Applying an explicit selection persists one full configuration, uses the existing model/provider replacement path, and publishes through the existing Watch configuration callback. Readings are never stored in templates. Existing widget configuration-match/cancellation guards remain in force.

The compact near-graph row has Save current and small configuration thumbnails. Selection indicates full configuration equality, not palette equality. Rename preserves the record ID and configuration. Delete requires confirmation and never alters active settings. Unsaved current settings require Save current / Use template / Cancel before switching. Malformed library bytes block writes and are left untouched; there is no destructive migration or default replacement.

The iPhone dashboard uses a 140-point graph left and semantic values/goals right when width and Dynamic Type permit. At larger text/small widths it stacks without progress-bar duplication. Values use primary text color with a small ring-color marker so light yellow palettes do not make values unreadable on white. The calendar arithmetic, midnight refresh, data queries and 37.1 date-boundary fix are untouched.

## Combined period integration

At parent request, the reviewed neutral-period commit `080c3b73b6fb76bae3399c42031762d4862ed225` was cherry-picked as `be9ab62` after the standalone candidate commit `4fe9719`. The only conflict was adjacent UI test insertion; both tests were retained. The saved-template UI assertion now reads the period's accessibility value, matching the delegate's separate label/value semantics. Its pixel test scrolls both measured regions fully on-screen at large text before cropping, because the adaptive legend now precedes the period. Production Period styling is the delegate's unchanged implementation: neutral label/value/chevrons/included cells, 44-point minimum target; midnight logic is unchanged. This is one combined candidate, not a separate period release.

## Glow findings (do not confuse characterization with a fix)

Existing configuration bindings, snapshots and Canvas inner/outer flags are connected. Controlled production-renderer captures show outer halo and inner edge highlight separately on all 11 shapes. The supplied recent screenshot resembles a non-glowing palette, but a screenshot alone does not establish its actual saved flags; no claim about the user's device configuration is made.

The old rectangular renderer used three fixed-radius SwiftUI shadows (`OuterGlow`: opacities .5/.2/.1, radius 12); the November 13 Canvas rewrite uses a single width-relative halo (.35, radius .42 × stroke width, reduced in simplified previews), and a clipped inner edge highlight. Thus historical glow appearance is not pixel-identical. This is not a disconnected toggle. No global blur/opacity increase or unverified renderer “fix” is made. Exact failing device settings/expected effect remain needed to choose a justified correction. Endpoint geometry, gradient reset correction, head compositing and masks remain unchanged.

Reproducible standalone macOS rendering (actual shared source, synthetic data, no HealthKit):

```sh
swiftc AnyRing/Shared/Views/Common/TripleRing.swift \
  AnyRing/Shared/Storage/CodableWrappers/CodableColor.swift \
  ci/RingGlowProbe.swift -o "$TMPDIR/ring-glow-probe"
"$TMPDIR/ring-glow-probe" "$TMPDIR/glow-matrix"
```

Evidence: `/Users/tinyserve/.hermes/cache/scratch/glow-mac-before/` contains actual PNGs for 11 shapes × dark/light × Off/Outer/Inner/Both. These are macOS ImageRenderer output, not iPhone runtime screenshots. No fake pixel measurements or Health values are used.

## Verification record

- RED: `templates-red.log` demonstrates missing save/select/rename/delete/library APIs before their implementation. Initial native UI RED attempt could not initialize AX (`Timed out waiting for AX loaded notification`); it is not a behavioral RED.
- Initial renderer XCTest filter selected zero methods. It is explicitly not counted as verification; whole suites are used subsequently.
- Standalone production renderer compiled and emitted the full glow matrix.
- Final standalone candidate Release suite: **86 methods / 94 parameter-expanded executions, zero failures** (`templates-final-verified.xcresult`). Includes complete legacy Config.v3 save/apply/relaunch tests, malformed-library preservation, real controlled datasource queries/stale widget results, Watch sync suites, 37.1 midnight/timezone lifecycle tests, endpoint pixel/seam matrix, widget privacy rendering, and three native UI tests.
- Native UI exercised synthetic archived Config.v3 (Heart-rate, min 35/max 60, reversed, minimum aggregation, name Resting, 5 days, Square, both effects). Saved it, changed source to Step count/default goal, period and shape, then selected and cold relaunched: source, goal, baseline, name, period, shape and effects restored. Largest Dynamic Type/French and existing foreground/query-count/palette cold-relaunch flows passed.
- Real iOS glow matrix asserts all four Off/Outer/Inner/Both raster outputs differ for all 11 shapes on both backgrounds. Endpoint continuity and complication masks pass with the unchanged renderer.
- A UI probe initially queried the virtualized period control while scrolled to the saved strip; scrolling back before querying corrected the test, not production logic.
- All four built bundle identifiers were checked: `com.potomushto.AnyRing`, `com.potomushto.AnyRing.RingWidget`, `com.potomushto.AnyRing.watchkitapp`, `com.potomushto.AnyRing.watchkitapp.RingWidget`. No project/signing/identifier changes. `git diff --check` and added-line security scan passed.

Evidence root: `/Users/tinyserve/.hermes/cache/scratch/templates-final-attachments/` (export manifest included):

- `3DB875F4-777D-4CB1-8CEB-CAB9FE4176E3.png`: restored complete configuration after cold relaunch, graph left/legend right.
- `A6A13C2B-33E0-4046-89A1-21341827F7E6.png`: actual restored source, goal 35, baseline 60, name, aggregation and both glow toggles.
- `0B2EFF92-5DA4-4798-B90F-513F048199FC.png`: largest accessibility text, stacked metrics without bars/clipped text (screen scroll continues).
- `FEA49629-3B01-4DDC-836B-F437DD26DC65.png` / `52A3887B-488F-4CBB-B911-CF95E187116E.png`: real iOS Square Off/Outer/Inner/Both, dark/light.
- `BE9B5824-6376-44F8-A11A-0BFAB302287F.png` / `EE2F83EF-F3B1-4725-BFFA-9C8429EEFC86.png`: same rounded-square matrix.

Owned simulator `734CD13C-DBAC-43D3-8738-7AC41B7A6A6B` was shut down and read back as Shutdown after exporting evidence. No other devices/processes were stopped.

## Final combined evidence

- `templates-combined-light.xcresult`: **87 methods / 95 executions passed**, including all unit suites and four native UI flows.
- `templates-combined-dark.xcresult`: **2/2 native UI methods passed**, complete legacy-active-config save/select/cold launch and neutral Period normal/maximum text.
- Visual review then caught the saved-header words splitting at maximum accessibility text. The header now uses a horizontal-or-stacked `ViewThatFits`, and saved thumbnail label widths scale with Dynamic Type. Normal-size thumbnails remain compact.
- `templates-accessibility-final.xcresult` exercised this final production code: **84 methods / 92 executions passed**; one new probe failed because it incorrectly demanded matching horizontal AX bounds for the caption and native inset button. The actual screenshot showed correct full words and stacked placement. The probe now checks the meaningful vertical relation instead; no production code changed after that run.
- Corrected probe: `templates-header-verified.xcresult`, **1/1 passed** at normal and maximum Dynamic Type. Screenshot reviewed for the final stacked header: `/Users/tinyserve/.hermes/cache/scratch/templates-header-verified-attachments/25793DE1-2354-496A-9E77-8D9262E05878.png`.
- Combined normal native screens: `/Users/tinyserve/.hermes/cache/scratch/templates-combined-light-attachments/EB2668AB-62EF-4BA7-ABF4-A6A05602C7D8.png` and `/Users/tinyserve/.hermes/cache/scratch/templates-combined-dark-attachments/F5B5CAF1-F3DB-44A6-8A3C-941BB5367826.png`.

All runs were serial on the task-owned simulator. After the final targeted run, `734CD13C-DBAC-43D3-8738-7AC41B7A6A6B` was again explicitly read back as **Shutdown**. No more simulator work is pending.

## Release-gate follow-up

The authorized publication of `83b7da7` reached hosted validation in run `44030432969` but did not upload. Its full Debug suite exposed an old workout UI navigation assumption (`Tests_iOS.swift:236`): after returning from lower metric editors, eight upward swipes moved farther away from Period. The accessibility failure listed the lower Appearance/metric rows, not the period. Corrected only that test's scroll directions, added explicit hittability and selected-period assertions; no production change or weakened assertion. The focused Release workout flow then passed on the task-owned SE (`anyring-release-83b7/workout-navigation-green.xcresult`); simulator shut down afterward. Final hosted validation/upload evidence is recorded in `ci/RELEASE.md`.

## Remaining acceptance boundaries

Physical-device HealthKit/Watch delivery and actual widget-host interaction are not established by fake-source tests. No claim of recovery of an undiscovered historical full-template database. Glow appearance correction remains unresolved rather than silently replacing old settings or inventing a new glow style.
