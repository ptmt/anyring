# HealthKit completion crash investigation

## Evidence and limits

Reported: TestFlight 2.0 (10.2), source `6c6387a306c52f0f34de036116911d8f4d6f9722`, exits after Health authorization. The supplied screenshot contains only the system crash/share alert, not an exception or backtrace. No physical-device `.ips` has been supplied. The simulator reproduction below demonstrates a reachable production defect, **not yet a symbolicated match to the user's device crash**.

No pre-existing AnyProgress diagnostic was present locally. App Store Connect credentials were not present in this process or the standard local API-key directories; existing CI signing secrets were not extracted. Sharing TestFlight feedback does not guarantee immediate crash-log availability. For an exact match, obtain the AnyProgress `.ips` from iPhone Settings → Privacy & Security → Analytics & Improvements → Analytics Data, together with iOS version and build number (or share the TestFlight crash).

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
- Full Release suite passed: 27 Swift Testing methods (the two new methods include 10 parameterized cases), two widget rendering tests and four UI tests. Existing unit compatibility, no-sample handling and Watch sync tests remain included.
- Independent read-only Codex review passed with no security or logic concerns (`review.txt` in the evidence directory); its optional suggestion to duplicate migration-value assertions is already covered by `invalidLegacyVO2SettingsAreMigrated`.
- 23 offline signing/profile/metadata tests passed; bash syntax, ShellCheck, actionlint (known runner-label rule excluded) and `git diff --check` passed.
- Unsigned simulator test hosts emit a missing HealthKit entitlement warning. The regression injects synthetic results and does **not** claim actual device HealthKit authorization testing. Shipping entitlements remain intact.
- CI now additionally runs the callback regression under Release; the original full Debug suite and all four archive targets remain.

Local evidence (not uploaded): `/Users/tinyserve/.hermes/cache/scratch/anyring-health-crash/` contains `red.xcresult`, `red.log`, `green.xcresult`, `green.log`, `full-release-2.xcresult`, `full-release-2.log` and `signing-tests.log`. The generated simulator report is `/Users/tinyserve/Library/Logs/DiagnosticReports/AnyProgress-2026-11-13-171154.ips`. Scratch evidence is temporary; this document preserves the relevant stack and result without Health samples or credentials.

## Delivery / acceptance

Release publication evidence will be recorded after the existing signed GitHub workflow finishes. Device acceptance remains required: grant Health permissions, verify readings/empty/denied states, relaunch with prior configuration, and verify paired Watch/widgets. A successful Apple upload alone does not establish TestFlight processing or device recovery.
