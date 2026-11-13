# HealthKit completion crash investigation

## Evidence and limits

Reported: TestFlight 2.0 (10.2), source `6c6387a306c52f0f34de036116911d8f4d6f9722`, exits after Health authorization and again on reopen. The initial screenshot contained only the system crash/share alert. The subsequently supplied TestFlight `crashlog.crash` confirms version **2.0 (10.2)** on **iPhone OS 27.3 (24C5037i)** with **EXC_BREAKPOINT (SIGTRAP)**, triggered thread 2.

The physical report's application frames match the simulator reproduction: frame 4 is `closure #1 in HealthKitProvider.calculateProgress(providerConfig:globalConfig:)`, frame 19 is `SendableCallback.call` (`DeviceHealthKitDataSource.swift:10`), and frame 20 is the statistics completion (`DeviceHealthKitDataSource.swift:67`). The intervening frames are Combine; the top images are libdispatch and libswift_Concurrency. Several **system-image symbol names are incorrectly attributed to app functions** in this supplied symbolication, so those names are not used as evidence. The matching application transform, actual statistics callback, exception type and simulator executor-assertion backtrace identify the same causal path. Reopening retries reads and can therefore trigger it again.

Only the crash entry was read from the supplied ZIP; personal `feedback.json` was not opened. No pre-existing AnyProgress diagnostic was present locally before reproduction. App Store Connect credentials were not present in this process or standard local API-key directories; existing CI signing secrets were not extracted. A second crash log is not needed to identify this failure; physical acceptance of the fixed build remains outstanding.

## Reproduction

A synthetic HealthKit data source completes authorization and reads on a background queue, exercising the real `AnyRingViewModel`, `HealthKitProvider`, `RingViewModel` and widget cache. It never reads/writes Health samples. The unchanged production implementation crashed in an optimized **Release** simulator test:

- `EXC_BREAKPOINT / SIGTRAP`, queue `com.apple.root.default-qos`.
- `_dispatch_assert_queue_fail` → `swift_task_isCurrentExecutorWithFlagsImpl` → `closure #1 in HealthKitProvider.calculateProgress(providerConfig:globalConfig:)` → `Publishers.TryMap.Inner.receive` → `Future.promise`.
- Xcode test command exited 65; the test host unexpectedly exited.

`RingProvider` is `@MainActor`; its conforming provider's `tryMap` closure inherits isolation. HealthKit resolves its Future on an arbitrary background queue. The existing `.receive(on: DispatchQueue.main)` in the **later UI subscriber** cannot protect the earlier `tryMap`. SDK headers explicitly document background HealthKit completion delivery; authorization/query closures themselves are sendable. The permission subscriber already hops correctly. WatchConnectivity delegates already hop through main-actor tasks.

The minimal fix adds `.receive(on: DispatchQueue.main)` immediately before the first actor-isolated progress transform. It also makes the subsequent widget snapshot map execute on main. No authorization, unit, migration, capabilities, identifiers, targets, signing assets or Health data behavior changed.

## Verification

Local Xcode 27.2, iPhone 18 Pro / iOS 27.2 simulator:

- The identical initial Release regression changed from crashed/exit 65 to passed/exit 0 after the scheduler boundary was added.
- Expanded tests cover main/background authorization and read delivery; populated, empty and denied results; new and restored legacy configuration (including archived colors and VO2 migration); authorization false/error. A preauthorization read returns no samples, so populated success requires the real authorization-triggered refresh.
- Full Debug and Release suites passed: each ran 27 Swift Testing methods (the two new methods include 10 parameterized cases), two widget rendering tests and four UI tests. Existing unit compatibility, no-sample handling and Watch sync tests remain included.
- Independent read-only Codex review passed with no security or logic concerns (`review.txt` in the evidence directory); its optional suggestion to duplicate migration-value assertions is already covered by `invalidLegacyVO2SettingsAreMigrated`.
- 23 offline signing/profile/metadata tests passed; bash syntax, ShellCheck, actionlint (known runner-label rule excluded) and `git diff --check` passed.
- Unsigned simulator test hosts emit a missing HealthKit entitlement warning. The regression injects synthetic results and does **not** claim actual device HealthKit authorization testing. Shipping entitlements remain intact.
- CI now additionally runs the callback regression under Release; the original full Debug suite and all four archive targets remain.

Local evidence (not uploaded): `/Users/tinyserve/.hermes/cache/scratch/anyring-health-crash/` contains `red.xcresult`, `red.log`, `green.xcresult`, `green.log`, `full-release-2.xcresult`, `full-release-2.log` and `signing-tests.log`. The generated simulator report is `/Users/tinyserve/Library/Logs/DiagnosticReports/AnyProgress-2026-11-13-171154.ips`. Scratch evidence is temporary; this document preserves the relevant stack and result without Health samples or credentials.

## Delivery / acceptance

**Apple upload succeeded** for **2.0 (12.2)** in [run 43461305997, attempt 2](https://github.com/ptmt/anyring/actions/runs/43461305997), source `5d9b0dd19d79b68959ad05d7d199752545c60418`.

- Validation job `132019554019` and upload job `132028928533` both succeeded.
- Signed archive: `ARCHIVE SUCCEEDED` at `2026-11-13T16:53:45Z`.
- Apple: `Progress 100%: Upload succeeded.` and `Uploaded package is processing.` at `2026-11-13T16:55:44Z`, followed by `EXPORT SUCCEEDED`.
- All original iPhone, widget, Watch and Watch-widget targets/capabilities retained. Cleanup succeeded; run has zero artifacts.
- Attempt 1 hit a hosted Xcode app-launch timeout before the first UI assertion. The other UI tests and all 27 Swift Testing methods passed. The sibling push run passed the complete workflow including Release regression. Rerunning failed jobs on the unchanged source passed and uploaded build 12.2; no checks were removed.

Device acceptance remains required: install 12.2 after processing, open with existing settings, grant Health permissions if prompted, verify readings/empty/denied states, and verify paired Watch/widgets. The physical crash report now matches the fixed path, but a successful Apple upload alone does not establish TestFlight availability or user-confirmed recovery.
