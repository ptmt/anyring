# Saved templates — failure not reproduced

## Outcome, November 18, 2026

The strengthened native **Release** flow passes on both the local candidate and the published source. The reported functional failure is **not reproduced**; no new root cause or functional fix is claimed. Only tests, this report and synthetic evidence are added. The candidate's previously implemented density, inline current/target labels, small-phone layout and rounded neutral week range remain unchanged and unpublished by this investigation.

The user's exact failing step and installed build remain unknown. The supplied `img_d254460da132.jpg`, inspected during the first investigation, shows the older Goal/From labels, square/underlined week, oversized saved row and blue plus. That establishes a presentation difference, not whether naming, saving, persistence or restoration failed.

## Fresh native verification

Xcode 27.2 (27B52), iOS 27.2 simulator, Release with `ENABLE_TESTABILITY=YES`, synthetic fixtures. No personal Health data was used or retained. Only these existing devices were used, sequentially with parallel testing disabled; neither was created, cloned, erased or deleted:

- Normal iPhone 17, 402×874pt: `93E1113F-6736-4CCB-827D-0E2F1C3876EA`.
- Small iPhone, 375×667pt: `56A70197-59DE-4410-9E76-25272244E9C8`.

| Run | Actual passing identities | Scope |
| --- | ---: | --- |
| `release-normal.xcresult` | **103/103**; 111 parameter-expanded executions | Entire candidate Release suite: 86 unit/widget/render identities and all 17 native navigation/UI tests |
| `release-published.xcresult` | **1/1** | Published `b916eaa7909f1929c6cafe213e419cda669a2ad5` production source, strengthened saved-setup UI method only |
| `release-small.xcresult` | **4/4** | Candidate saved setup, empty/populated density lifecycle, accessibility XXXL, included-week 1/2/3/5/7 presets |

Every result bundle was read with `xcresulttool`: zero failed/skipped tests and zero reported runtime warnings. Both new ConfigurationTests methods executed and passed, not merely parsed. Offline CI discovery also passed **28 tests**, and `git diff --check` passed.

Build logs contain Xcode's debugger-version lookup diagnostic; the unsigned unit host also logs a missing HealthKit entitlement. These did not fail assertions; this is synthetic simulator verification, not a claim of physical-device Health authorization or real-data acceptance. Light appearance was retained on both devices; dark-mode native tests were not rerun in this investigation.

### Actual UI sequence, not just storage

The same strengthened test passed on candidate normal, candidate small and published normal:

1. Tap the actual hittable save/plus control; require the **Save template** alert.
2. Require Save disabled for empty and three-space names; replace with **Recovery** and require Save enabled immediately.
3. Save and require a visible selected saved card.
4. Change period from five to seven days, shape from rectangular to circle, and the first source from Heart-rate to Step count; require the changed source's goal of 8000 and deselected saved card.
5. Tap the saved card, confirm **Use template**, require five days and selected card.
6. Terminate and cold-launch with explicitly preserved synthetic settings; require saved card selected, rectangular shape, Heart-rate source, **Resting** custom name, goal **35** and starting baseline **60**.

The selected trait is derived from `record.config == model.config` in `TemplateView.swift`, so selection checks complete configuration equality, not only a selected record ID. The restored editor screenshot also visibly retains Minimum aggregation, reversed direction, mint color, Gradient off and both glow switches on.

Separate density UI coverage exercised save, rename, delete-cancel and confirmed deletion. The full navigation gate also exercised period/shape persistence, source search, palettes/glow, custom names, keyboard/French/accessibility flows, widget links, workout-source selections and real synthetic pull-to-refresh query assertions. Unit coverage includes complete legacy configuration restoration, stale-read fencing, malformed-library preservation and name validation.

## Full setup evidence and inspected screens

`SavedConfiguration` stores the entire `AnyRingConfig`, not an appearance palette. The saved library and the restored Config.v3 payload were read back only from this app's synthetic test preferences. Full synthetic settings are retained under `docs/evidence/saved-templates/`:

- `candidate-restored-settings.json`
- `published-restored-settings.json`

The saved configuration objects in these two receipts compare equal across all three sources, units/aggregation, goals/baselines, custom labels, appearance, period and shape. Config.v3 retains its legacy archived-color representation; the saved library uses decoded color components. No cached Health readings or unrelated app preferences were exported.

The following full, unmodified runtime PNGs were individually inspected:

- `candidate-empty-normal.png`: one compact **Save current setup** row, rings beside inline readings, rounded neutral included range, Appearance visible.
- `candidate-saved-normal.png`: **Daily setup** thumbnail/name/checkmark visible; separate appearance palettes remain below.
- `candidate-empty-small.png`: same layout at 375pt; the long step target wraps without forcing the rings above the legend. Shape remains visible.
- `candidate-saved-small.png`: saved card fully visible; Shape is at the bottom of the viewport and palettes require scrolling.
- `candidate-restored-editor.png`: restored source/name/goal/baseline and appearance switches after cold launch.
- `published-restored-normal.png`: **Recovery** survives cold launch even with the older tall saved row, blue plus and Goal/From presentation.

Native geometry receipts measure the candidate empty row at **74pt** on both devices; populated row is **176.667pt** normal and **177pt** small. The populated save control is **44pt** high. No oversized empty carousel region appears. These fresh observations support the existing compact presentation, not a claim that the unknown user failure was fixed.

## Comparison and scope

Candidate base: `20d261fe092dcf794ae397ec71e6c128ef544271`, branch `investigate/saved-templates`, worktree `/Users/tinyserve/Projects/anyring-saved-templates`.

For the published differential, `git archive b916eaa` was extracted to task-owned scratch and only `testSavedConfigurationStripRestoresCompleteSettings` was replaced by the candidate's strengthened test method. No published production source was changed. Its actual old plus/naming/save/restore/cold-launch flow passed. This is a locally compiled Release comparison, not execution of the signed TestFlight binary.

Earlier investigation receipts recorded successful hosted run `44034134268` on b916eaa, Apple upload build **41.2** at `2026-11-17T07:43:05Z`, and a successful hosted saved-template UI regression. Those are historical receipts, not a fresh check of current remote main, Apple processing, tester availability or the user's installed version. No push, upload, release or new remote action occurred here.

New tests cover trimmed/empty/whitespace names; rejected save/rename preserving current settings, records and bytes; same-name distinct identities; duplicate IDs/null/missing names failing closed without deleting bytes; additive fields and legacy empty display names remaining decodable. The UI regression now explicitly checks the naming and enablement boundary. No production code was changed because no functional RED was found.

Original `/Users/tinyserve/Projects/anyring` HEAD, exact dirty status and all **13** dirty-file SHA-256 hashes were compared with the inherited manifest before and after execution and preserved. Other worktrees, including KeineMagie camera work, were not modified.

## Reproduction and retained receipts

Scratch root: `/Users/tinyserve/.hermes/cache/scratch/saved-templates-native/` contains build logs, three xcresults, exported attachment manifests, original-preservation receipt and published-source archive. Concise result summaries, the six inspected PNGs and two synthetic settings receipts are retained in `docs/evidence/saved-templates/`.

Normal candidate command (result destination must not already exist):

```sh
xcodebuild test -project AnyRing/AnyRing.xcodeproj -scheme 'AnyRing (iOS)' \
  -configuration Release \
  -destination 'platform=iOS Simulator,id=93E1113F-6736-4CCB-827D-0E2F1C3876EA' \
  -derivedDataPath "$SCRATCH/build" -resultBundlePath "$SCRATCH/release-normal.xcresult" \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  CODE_SIGNING_ALLOWED=NO ENABLE_TESTABILITY=YES ONLY_ACTIVE_ARCH=YES
```

The small run uses `test-without-building`, the same candidate DerivedData, the small UUID and four explicit `-only-testing:Tests iOS/Tests_iOS/...` filters listed in the results table. Published comparison uses separate DerivedData and the single saved-setup filter. Available disk was 108GiB before building and 107GiB after. Both reused devices were read back **Shutdown**; no active Xcode test remained. The shared simulator slot is released.

## Remaining diagnostic question

> Когда нажимаешь «+», окно с названием появляется? Если появляется: после ввода названия кнопка Save становится активной, и что происходит после нажатия — шаблон не появляется, исчезает после перезапуска или не возвращает настройки?

Ask for the installed TestFlight build if needed to bind the answer to a version. Do not infer build 41.2 solely from the screenshot or present the unpublished visual changes as an already delivered functional fix.
