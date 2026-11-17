# Dashboard density candidate — UI gate pending

## Base and scope

- Isolated branch `fix/dashboard-density`, worktree `/Users/tinyserve/Projects/anyring-dashboard-density`.
- Fresh `git ls-remote` confirmed `main` at `5e7d424d25e4863657279ac8804e8c23ab9f777f`. GitHub release run `44034134268`, attempt 2, reports success at source `b916eaa7909f1929c6cafe213e419cda669a2ad5` (2.0 / 41.2 in release documentation). There is no AnyRing source diff between those two commits.
- Layout only. No formatter, aggregation (including mean steps), provider, persistence codec, cache fence, ring renderer, palette, effect, identifier, entitlement, Watch or widget changes. Existing midnight refresh and full-configuration save/select/rename/confirmed-delete/unsaved-change behavior remain intact.
- Do not push or release before actual runtime inspection and parent visual approval.

## Reported screen and investigation

Inspected the supplied JPEG with vision, not a reconstructed mockup:
`/Users/tinyserve/.hermes/cache/documents/native-inputs/3a4a6f1dc4dc5ec4da0aa154cf8f8096e68aa565539db0253f2850efb525f4b0/img_36e07595f0b0.jpg`.

The empty Saved templates row is visibly far taller than its header, pushing Appearance down. The week uses square gray selected cells and a continuous dark underline. Rings already sit left of the complete legend, vertically centered; that relationship and the existing numeric text are preserved.

Source trace:
- `MainScreen` places `RingDashboard` and `SavedConfigurationsView` in **separate Form rows**. Dashboard vertical padding is only 8; there is no large padding or negative-padding correction to remove.
- The empty library **does not instantiate its horizontal ScrollView**. Calling this an empty carousel reserving thumbnail height would be incorrect.
- Its always-present `ViewThatFits` header, with a flexible HStack/Spacer first choice, had no intrinsic vertical sizing at the Form-row boundary. This is the leading iOS row-sizing hypothesis, not yet a runtime-confirmed root cause. No GeometryReader or max-height frame exists in that empty view.
- A lightweight macOS SwiftUI ImageRenderer probe of the old header alone returned 44pt at proposed heights 100/300/600. It **did not reproduce the iOS Form bug**; it rules out claiming that the header alone invariably expands. Real iOS Form measurements are still required.

Candidate removes the adaptive header entirely from the empty path: one plain, neutral, title-and-plus “Save current setup” action with a minimum 44pt target. The full saved view and the populated horizontal strip request intrinsic vertical size, rather than accepting an arbitrary row-height proposal. The nonempty header retains its accessible stacked fallback and real thumbnail strip. No fixed thumbnail-strip height or magic negative padding is introduced.

Week inclusion is now marked by small neutral dots beneath seven equal-width dates, with the existing semibold included dates and explicit Today label. No table background or underline. Calendar arithmetic, Menu choices, accessibility date/value text and lifecycle callback are unchanged.

## Measurement ledger — do not fill with inferred points

| State | Released baseline | Candidate |
|---|---|---|
| Supplied screenshot raster | 588 × 1280 pixels | Not applicable |
| White card rails at x=60 and x=540 | y=146…979, 834 raster pixels (AppKit pixel scan) | Pending actual iOS capture |
| Empty saved Form row, 390pt ordinary text | Pending exact runtime frame | Pending; regression requires ≤80pt including native row insets |
| Populated saved Form row, ordinary text | Pending exact runtime frame | Pending; regression requires ≤200pt |
| Dashboard card union, ordinary text | Pending | Pending |
| Small phone / accessibility XXXL | Pending | Pending |

The supplied JPEG scale/device is not established; its pixels are **not** relabeled as points. The visually blank space below the divider is evidence of the complaint, not a measured 300pt row.

## Executed without the heavy-test slot

- Three lightweight source-structure regressions each failed before their corresponding edit and now pass. These guard the empty branch, intrinsic sizing boundaries, and removal of the week underline. They are **not** SwiftUI geometry tests.
- All 26 Python CI checks pass (23 existing + those three guards).
- `swiftc -frontend -parse` passes for the four edited Swift files. This is syntax parsing, **not iOS typechecking**.
- `git diff --check` passes.
- No Xcode build/test, simulator boot, install or launch was performed. The sole heavy-test slot belongs to KeineMagie passage-groups (`sa-0-3e38613c`) until the parent assigns it.

## Prepared native verification

`testDashboardDensityEmptyAndSavedRows` records actual viewport/dashboard/saved-row/save-button CGRect attachments and screenshots, checks empty-row height and first-screen Appearance, then exercises save, selected state, rename, cancel-delete, confirmed delete and restored empty-row geometry.

`testDashboardDensityAccessibilityContent` checks all three named metric/goal elements and the footer at accessibility XXXL, with per-region real screenshots. Existing neutral-color/menu and complete saved-config restore/cold-relaunch tests remain, with only the empty-footer assertion adapted from the removed header to its single action.

The simulator-only `--dashboard-density-fixture` is nested inside existing explicit `--ui-testing` reset handling. It configures HRV / Step count / Heart-rate, goals 100 / 15,000 / 42 with HR baseline 80, three days and squircle; it uses the existing synthetic provider values and default appearance. It creates **no saved templates** and does not change production defaults or user data. These fixtures match the reported metric/goal layout, not its personal readings or chosen palette.

After the slot is assigned:
1. Build a baseline from the released source with **only** the fixture/new density test transplanted; run the ordinary density test to capture the real failing row and its bounds. Retain the expected failure rather than weakening it.
2. Build/test candidate Release on a 390pt ordinary-width device, light then dark, sequentially. Export/inspect empty and populated screenshots and CGRect attachments; measure the card union from the real frames. Restore device appearance afterward.
3. Repeat on a small phone and accessibility XXXL; inspect full names/units/goals, explicit Today, and footer wrapping. Scrolling is expected at accessibility sizes; fabricated empty height is not.
4. Run existing full saved-config restoration, period/cache/query/midnight, unit/widget regressions. Parse nonzero test counts and check actual screenshots, not merely successful build status.
5. If the old row does not fail or the candidate still expands, return to iOS Form proposal tracing before asserting a root-cause fix. Record measurements and evidence paths here, then seek parent visual approval. No release is authorized by this candidate.

## Preservation

Original worktree's 13 dirty files, HEAD, exact porcelain status and index hash were recorded at `~/.hermes/cache/scratch/dashboard-density-original.json`. No original or released worktree files were edited. Candidate changes are confined to the two presentation views, simulator-only fixture, UI tests, lightweight guard tests and this document.
