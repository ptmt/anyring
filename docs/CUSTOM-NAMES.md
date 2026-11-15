# Per-ring custom names candidate

## Scope

Based on `ed9017de67fceb55f857e6f4341e76e165a22ef8`. Independent review integrated the candidate into clean `/Users/tinyserve/Projects/anyring-custom-names-release` on `release/per-ring-custom-names`, based on fetched `c2ee4607efef4df1ca68fb5322880c8b1acbf776`. The remote gap was verified as 11 documentation-only lines in `ci/RELEASE.md` and is retained. The original dirty `/Users/tinyserve/Projects/anyring` and the implementation candidate were not edited by the reviewer.

- Optional `customName` on each existing provider configuration; missing/null/blank falls back to the metric name. Leading/trailing whitespace is trimmed and values are bounded to 40 Swift Characters (extended grapheme clusters).
- Native field and accessible 44-point Clear Name control in the existing ring editor. Changes persist while typing; the input buffer retains spaces so multiword typing works. Metric selection and Data Source retain the actual metric name.
- Shared display names feed iPhone/Watch metrics and VoiceOver, ring links, and both widget targets. Narrow rectangular widgets reserve percentage width; inline truncates in the middle, preserving percentage. No widget-specific settings.
- Label-only changes keep ring models/progress and do not issue extra app-side Health reads. Saved cache is rebound only when all non-name fields match, retaining acquisition date. Old-name cache requests fail exact matching. An already-running app snapshot can finish with current labels only when its complete non-name configuration still matches; other changes retain generation/persistence fences.
- The widget provider retains its existing Health refresh policy on a timeline reload; this candidate does not claim zero extension-side Health queries.
- Goal/normalization/aggregation implementations, icons, endpoint drawing, HealthKit adapters, privacy manifests, entitlements and native pull-to-refresh are unchanged. Tests explicitly preserve heart-rate goal 42, start 80, reversed/minimum through rename.

## Executed verification

Xcode 27.2, isolated iPhone 18 Pro / iOS 27.2 simulator `C55B37A3-F025-434D-A63F-1EE731335DC9`. Synthetic fixtures only.

Evidence root: `/Users/tinyserve/.hermes/cache/scratch/anyring-custom-names/`.

- RED: `red-model3.xcresult` failed because customName was dropped on JSON decoding/encoding. `red-rename2.xcresult` failed the name/reading/cache behavior. `red-ui.xcresult` failed missing editor field.
- GREEN: `release-final.xcresult`: **70 test methods / 78 parameter-expanded executions**, zero failures, skips or runtime warnings. Includes actual Release rename/relaunch/clear, accessibility XXXL/long-name limit, original no-refresh-chrome and real pull gesture six-query/cache-date regression, old JSON, Unicode family emoji, Watch snapshot/application, pending widget read, cache identity and render/privacy/endpoint tests.
- `python3 -m unittest discover -s ci/tests -v`: **23 passed**. `git diff --check`, `bash -n ci/testflight.sh ci/cleanup.sh`: passed. Added-line secret/injection scan: no matches.
- Unsigned Release device archive `AnyProgress-final.xcarchive`: succeeded, containing iPhone app, iPhone widget, Watch app and Watch widget. No upload/signing/release performed.
- Exported and inspected real Release screenshots in `final-screenshots/`: dashboard `94345529-495E-4367-A030-1C4568C1E0EA.png`, editor `A5261112-270E-47D8-BA3B-CD98BB28A035.png`, accessibility dashboard `4577D40A-EA2D-473C-B203-A91E1C15A73C.png`, accessibility editor `0A688F4E-7CC0-4D54-83FC-668AB677C889.png`, rectangular widget `B4E149DA-3779-405A-B938-B99BC6F33DC2.png`, inline `F1D56AFE-DA17-4672-BE22-ED8623B53C5D.png`, compact Watch metric `2431F291-C1B7-4270-909B-3BC2F8E31F09.png`.
- Long dashboard/compact titles wrap. Single-line editor scrolls/truncates at accessibility size with clear action still accessible. Initial widget render exposed lost percentages; final renders preserve 25%, 50%, 100% despite long names. Watch-sized metric rendering uses the shared production view in an iOS ImageRenderer, not a physical Watch screenshot.

Repro command (use a fresh result path):

```sh
xcodebuild test -project AnyRing/AnyRing.xcodeproj -scheme 'AnyRing (iOS)' -configuration Release -destination 'platform=iOS Simulator,id=C55B37A3-F025-434D-A63F-1EE731335DC9' -derivedDataPath /Users/tinyserve/.hermes/cache/scratch/anyring-custom-names/build -resultBundlePath /Users/tinyserve/.hermes/cache/scratch/anyring-custom-names/recheck.xcresult CODE_SIGNING_ALLOWED=NO ENABLE_TESTABILITY=YES ONLY_ACTIVE_ARCH=YES
```

Initial harness issues: Release needs `ENABLE_TESTABILITY=YES`; an individual Swift Testing filter without `()` selected zero tests, so validation used complete suites and checked xcresult totals. UI backspace-at-tap-caret did not clear the whole field; explicit Clear Name was added and actual clearing/relaunch passed.

## Independent review

- Reviewed all 11 changed source/test files against the baseline and the docs-only remote gap. No substantive production defect found; implementation code is unchanged by review. Added three regression tests: explicit missing/null/whitespace/unknown JSON fields and invalid name types (rejected as `DecodingError`), pending app-read rename retaining its result without queries, and name-independent privacy pixels for all three accessory families. These characterize existing candidate behavior; no new production fix or RED/GREEN claim is made for them.
- Fresh Xcode 27.2 Release build/test on the isolated simulator above: `release-final.xcresult` **73 methods / 81 parameter-expanded executions**, zero failures/skips/runtime warnings. Nine actual UI tests include rename/relaunch/clear, long names at accessibility XXXL, preserved Data Source, no-refresh-chrome and real six-query pull-to-refresh/cache date. Background HealthKit callbacks, pending snapshot renames, Watch snapshot application and cache identity tests passed.
- **23 Python tests**, shell syntax and `git diff --check` passed. Added-line secret/injection scan had no matches. Icons, endpoint renderer, project/identifiers/profiles, entitlements and workflow are unchanged from the approved release.
- Independently inspected exported actual Release screenshots in `/Users/tinyserve/.hermes/cache/scratch/anyring-custom-names-review/screenshots/`: normal and XXXL editor/dashboard, long-name rectangular and inline widgets, compact shared Watch metric. Clear remains separate; Data Source still says HRV; dashboard wraps. Rectangular preserves **25%, 50%, 100%** and inline **25%**. Editor text truncates/scrolls rather than overlapping its clear control. Compact Watch render is synthetic shared-view evidence, not physical Watch evidence.
- Original dirty main HEAD and all **13** changed/untracked file hashes matched the review-start manifest. The implementation candidate remains untouched. Synthetic test suites only; no user Health data or credentials accessed.

## Hosted fixture failure and correction

Initial source `855a62a978feebba015f3c5c2cc7c92721b488f8` passed local Release but both hosted runs exposed existing fixed-sleep fixture races under MainActor rendering load. Publish run `43699094850`, job `132766022254`, failed at `ConfigurationTests.swift:719`/`:723` (cancellation registration counts), then resumed an already-completed controlled continuation with 999 in the stale widget snapshot test. Push `43699088655`, job `132765997432`, also failed cancellation counts and had an Xcode launch timeout in the XXXL UI test at `Tests_iOS.swift:219`. Neither run uploaded.

The narrow test-only correction waits for required query registration before capturing explicit, disjoint read ranges; it waits for observable completion where needed, and cancels spawned queries on exit. Existing assertions remain, with a failing bounded prerequisite before unsafe continuation access. Production HealthKit and feature code are unchanged. Hosted failures are RED evidence; subsequent local/hosted results are recorded below and in `ci/RELEASE.md`.

## Release and evidence retention

Source `d33b3e8c91823c79aac228f90b59c43eb7c2e82b` uploaded as **2.0 (31.3)** in [run 43701626684 attempt 3](https://github.com/ptmt/anyring/actions/runs/43701626684). Validation `132785638803`, upload `132792416014`; Apple explicitly confirmed upload at `2026-11-15T11:15:51Z`. Final local fixture-corrected full Release remains **73 methods / 81 executions**, zero failures/skips/runtime warnings. Final hosted full suite and separate Release checks passed. Failed readiness/launch attempts and the green same-SHA push are retained in [release evidence](../ci/RELEASE.md).

Post-upload, only the review-owned DerivedData and three xcresult bundles were removed with tool approval. Compact summaries, exported screenshots, CI logs and original-file hash manifest remain in `~/.hermes/cache/scratch/anyring-custom-names-review/`. Earlier implementation evidence was not deleted.

## Review boundary

Physical paired Watch delivery, installed lock-screen widgets and real Health permission/data behavior are not claimed. Upload is verified; Apple processing completion and tester availability are not.
