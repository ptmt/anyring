# Endpoint rendering verification

Base: `origin/main` `4fcb0e54a7bd825d0ce50e49ca02b43c42178210` (14.1 documentation; app source `47c90baa4f8cdcbf67f5dcd95278a83ae518e7ed`). Worktree: `/Users/tinyserve/Projects/anyring-endpoint-fix`, branch `fix/ring-endpoint-compositing`. The original dirty worktree was not opened or modified.

## Cause and narrow correction

Two independently reproduced compositing defects in `TripleRing.swift`:

- A secondary-color reset stop only `0.00001` after the primary-color stop introduced a narrow dark stripe in the **filled side** of the conic gradient. Removing only that unnecessary reset for partial arcs removed the stripe in real SwiftUI pixels. Complete/extra laps retain their deliberate gradient discontinuity.
- An opaque independently lit head disc, full circular white stroke, and its shadow were painted over the already shaded tube. The trailing rim/shadow visibly marked an internal join. Fade the head's trailing half into the existing tube and restrict its shadow receiver; retain the leading shaded tip, soft external shadow, inner/outer glow, shapes and advancing extra-lap head. The full-circle internal rim is intentionally no longer drawn. Near-full yellow still overlaps the darker beginning of its own ring; that color boundary is intentional.

Contour point/path/tangent tests agree within CoreGraphics float-coordinate precision. No contour rewrite was needed. No settings, identifiers, capabilities, HealthKit async code, or release versions changed.

## Actual verification

Xcode 27.2, isolated iOS 27.2 simulator:

- Red pixel test: constant-color cap/body adjacent-pixel jump **20**, limit 4. After: **2**.
- Second red pixel test: partial gradient jump **35**, limit 4. After: **3**; 1.5 and 2.5 laps: **4**.
- Full Debug and optimized Release: **53 Swift Testing methods, 2 widget XCTest methods, 6 UI tests**, all passed in each configuration. This includes the existing synthetic background HealthKit authorization/read crash regressions, privacy rendering and shape-mask checks.
- Endpoint matrix: all **11 shapes × 3 sizes (44/140/300 pt) × 21 states = 693 real ImageRenderer renders** per suite, including zero, near zero, half, near one, one, over one and sampled `RingMotion` frames. Pixel inequality verifies intermediate frames redraw. Geometry tests verify path endpoints and normalized tangents across laps. These matrix checks are coverage/smoke tests, not a claim that every image is a golden pixel match.
- Unsigned iOS Release and watchOS Debug/Release production builds passed. Real watchOS simulator launched a separate, clearly labeled **SYNTHETIC** harness compiling the production ring sources; rounded-square tips/glow inspected. All-shape Watch-size matrix is iOS ImageRenderer output, not eleven watchOS runtime screenshots.
- `git diff --check` passed. No live Health data used. Unsigned host emits expected missing HealthKit entitlement diagnostics; no actual Health authorization claim.

Release tests require command-line `ENABLE_TESTABILITY=YES ONLY_ACTIVE_ARCH=YES` for the existing `@testable` import; the initial invocation without testability failed at compilation. Project build settings were not changed.

## Evidence / reproduce

Local evidence: `/Users/tinyserve/.hermes/cache/scratch/anyring-endpoint/`:

- `ios-comparison.png`, `ios-tips-before-after.png`: actual iOS before/after synthetic fixture (outer 0.48, middle 0.50, inner 0.97).
- `all-shapes-watch-scale.png`, `pointed-and-square.png`, `watch-runtime.png`, `synthetic-animation.gif`.
- `red.xcresult`, `red-gradient.xcresult`, `full-debug-2.xcresult`, `full-release-2.xcresult`, matching logs and exported `debug-attachments/`.

Standalone macOS SwiftUI production renderer (no HealthKit or preferences):

```sh
swiftc AnyRing/Shared/Views/Common/TripleRing.swift \
  AnyRing/Shared/Storage/CodableWrappers/CodableColor.swift \
  ci/RingEndpointProbe.swift -o "$TMPDIR/ring-endpoint-probe"
"$TMPDIR/ring-endpoint-probe" "$TMPDIR/ring-endpoint-images"
```

The candidate's CLI review attempts were blocked by unavailable models. Subsequent independent integration review inspected the complete production/test diff, actual before/after pixels, and both successful xcresult summaries (61 methods each, 69 parameter-expanded executions). No security or blocking logic findings: the gradient reset remains for extra laps, shadow receivers preserve the leading tip, and inner/outer glow, shapes, motion and data paths remain intact. The parent also accepted the substantial visual improvement. Physical iPhone/paired Watch/actual widget-host acceptance remains separate. The tips deliberately retain light/shadow; a subtle curved tonal transition is still visible in an enlarged orange crop, not the old hard stripe/rim.

## Graphite integration and CI diagnosis

Only the four endpoint source/test/probe/documentation files were integrated onto Graphite icon commit `5cd05fd9ae5b269fde177095a5f1058986e5cf5e` in the clean `anyring-graphite-release` worktree. Icon assets, all four target IDs, capabilities and existing HealthKit implementation were retained. The production renderer compiled and generated its synthetic fixtures again; all 23 offline signing/configuration tests passed.

The earlier icon-only push validation [43603652881](https://github.com/ptmt/anyring/actions/runs/43603652881) failed before the tracking-period test's assertions, at `Tests_iOS.swift:66` (`app.launch()`): **Application 'com.potomushto.AnyRing' does not have a process ID**, after 160.424 seconds. The explicit publication [43603667164](https://github.com/ptmt/anyring/actions/runs/43603667164) on the identical SHA passed the same complete suite and uploaded icon-only build **17.1**. This is consistent with the previously observed hosted simulator launch/timing failure, not an endpoint regression (endpoint changes were absent). No test assertions, capabilities or product code were weakened to bypass it. Final combined publication evidence is recorded in [ci/RELEASE.md](../ci/RELEASE.md).
