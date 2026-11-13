# Lock Screen widget release

## Scope and local verification

The authorized release includes the existing circular/rectangular/inline widgets,
matching real-health cache, privacy-safe geometry, and strict widget deep links.
All four original phone/Watch app and widget bundle IDs, team `49PJNAT2WC`,
HealthKit, and `group.49PJNAT2WC.com.potomushto.AnyRing` are preserved.

The local checkout was six commits behind origin/main. Those remote CI changes
were fast-forwarded before integrating the local widget work. The owner's short
README/name-review note is preserved; detailed app documentation is in `docs/APP.md`.

Verification on Xcode 27.2:
- 25 Swift unit/regression tests, two production-widget rendering tests, and four
  UI tests passed (31 total).
- Initial period-persistence UI test failed because its second launch removed the
  explicit fixture flag, correctly activating real HealthKit instead. Relaunch now
  retains the fixture flag with a separate preserve-settings flag; production
  simulator launches still use real HealthKit. The complete suite then passed.
- Unsigned Release device archive including both Watch targets passed.
- 22 offline signing/metadata/profile-ownership tests passed, as did ShellCheck,
  bash syntax, plist syntax, and actionlint (only its stale runner label check is
  narrowly excluded; the actual runner was verified from GitHub logs).
- Scoped source/diff review found no hardcoded credentials. Parent-agent independent
  verification is separate; this commit does not claim an independent reviewer verdict.

## Delivery

Apple upload **succeeded** in [run 43433248233, attempt 2](https://github.com/ptmt/anyring/actions/runs/43433248233).

- Release head: `6c6387a306c52f0f34de036116911d8f4d6f9722` (includes widget commit `c02d6f98b79d43dd185176c2abc0f9d6f4ab0d27`).
- Marketing version: `2.0`; archived/uploaded build: **10.2**.
- Validation job: **131918537263**; upload job: **131922384997**.
- Hosted validation: **23** Python tests and **31** Swift/widget/UI tests passed;
  simulator build and unsigned Release archive also passed.
- Hosted signing validated all four profiles' original team/bundle IDs, HealthKit,
  App Group, validity dates, and exact distribution-certificate membership.
  The signed archive succeeded with both Watch targets retained.
- Apple's output at `2026-11-13T13:49:53Z`: **“Progress 100%: Upload succeeded.”**,
  **“Uploaded package is processing.”**, followed by **`** EXPORT SUCCEEDED **`**.
- Cleanup step succeeded; GitHub reports **zero artifacts** for this run.

The first publication (run 43430329177, build 8.1) passed signing but Apple rejected
it because the Watch app lacked `NSHealthUpdateUsageDescription`. Added the truthful
read-only purpose string and a RED→GREEN regression covering every HealthKit plist.
Attempt 1 of the final run hit a hosted simulator launch timeout before assertions;
its sibling push run passed. Rerunning the failed jobs on the same unchanged SHA
passed all tests and delivered build 10.2. No checks or Watch capabilities were dropped.

Upload is verified; Apple processing completion, compliance, tester assignment,
and availability on a physical device are **not** yet verified.

## HealthKit crash hotfix — 2.0 (12.2)

The subsequent on-device 10.2 crash report matched an independently reproduced
Release simulator executor assertion in the HealthKit progress transform. The fix,
RED/GREEN evidence and physical-report correlation are in `docs/HEALTHKIT-CRASH.md`.

- Source: `5d9b0dd19d79b68959ad05d7d199752545c60418`.
- [Run 43461305997, attempt 2](https://github.com/ptmt/anyring/actions/runs/43461305997): validation `132019554019`, upload `132028928533`, both success.
- Signed archive and explicit Apple **Upload succeeded** verified; build **12.2**,
  marketing version **2.0**. Apple reported processing at `2026-11-13T16:55:44Z`.
- All four shipping targets/capabilities preserved; cleanup success, zero artifacts.
- Full Debug and Release tests passed locally; hosted validation includes the full
  Debug suite plus the new Release background-callback regression. Independent
  code review passed. Attempt 1 had a hosted UI launch timeout; unchanged retry passed.
- Processing completion, tester availability and fixed-build physical acceptance
  remain unverified. Do not ask for another crash report to identify the original
  failure: the supplied report has already been correlated.

## Device acceptance still required

After Apple processing and tester assignment, verify actual iPhone Lock Screen
installation, locked HealthKit/cache behavior, privacy/Always On, and paired Watch
configuration/complication updates. Automated rendering does not install a widget.
