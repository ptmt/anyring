# Approved dark Graphite icon

Owner approved the **right-hand constant-offset** design ("справа"). This revision changes icon PNGs only; the app's production ring geometry is not changed.

## Source and geometry

- Master: `/Users/tinyserve/Projects/AnyProgress-icon-concentric/AnyProgress-Dark-Graphite-Concentric-1024.png`.
- SHA-256: `7f60d6dd1a42673c72e0089a8c4668d191b69c480677f40df27fad3f56219134`.
- Opaque RGB, embedded sRGB, 1024 × 1024. Full square artwork, no baked corner mask.
- Dark background `#202329`; Graphite fills 95% / 88% / 80%; motif footprint 680; icon-only constant-offset radii 232 / 143.6 / 55.2. Source design evidence records shared corner centers and positive innermost inside-edge radius.
- Export uses the approved master directly, not the earlier white Graphite master or the left-hand candidate. All 1024-pixel catalog assets are byte-identical to this master. Smaller variants use the established Pillow LANCZOS packaging algorithm and retain the master's ICC profile.

## Verification

- Regenerated **55 PNGs**: Shared 22 files / 25 slots; Watch 15 files / 15 slots; RingWidget 18 files / 18 slots. All three existing `Contents.json` manifests are byte-unchanged; legacy filenames are intentionally retained.
- Each file verified for dimensions, RGB/no alpha, sRGB, dark corner pixels, expected downsampled pixels and SHA-256. Every PNG differs from its previous white asset. Identical dimensions across catalogs intentionally share the same image bytes; the three catalogs retain their distinct manifest/slot sets.
- All three actual asset catalogs compiled with Xcode 27.2 `actool`, exit **0**; Watch compiled separately for `watchos` / `watch`. Rounded and circular Watch previews have no visible clipping. At 16px fine ring detail is limited; no size-specific redesign was introduced.
- All **23** existing offline configuration/signing tests passed; shell syntax and `git diff --check` passed. Hosted full validation and upload status are recorded separately in [RELEASE.md](../ci/RELEASE.md).
- Based on fetched `bbee324e9e41067be1f509ca8a42792d612ff91b`, retaining released source `79e67fdc95287f15e9e32a464e249718358ff453` and its endpoint compositing fix. `TripleRing.swift` remains SHA-256 `fbaeedcfd047a7aa2505bc506cc1426ff16464b0741d1d897f83549e7a17b3bc`.
- All production Swift, four shipping target IDs, HealthKit/App Group entitlements, profiles, project settings and CI remain unchanged. Original dirty worktree's 13 files match their existing backup manifest; no reset/stash/checkout was performed there.
- Local export script, 55-file hash proof, actool logs and masked preview PNGs: `~/.hermes/cache/scratch/anyring-dark-concentric-release/`. Approved source art remains in the durable master directory above.
