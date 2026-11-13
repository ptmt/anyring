# AnyProgress releases

## Combined laptop features + async HealthKit — 2.0 (14.1)

Published with the owner's explicit authorization on 2026-11-13.

- Source: [`47c90baa4f8cdcbf67f5dcd95278a83ae518e7ed`](https://github.com/ptmt/anyring/commit/47c90baa4f8cdcbf67f5dcd95278a83ae518e7ed), directly atop fetched `48da9cbdfc6cdd33a6e1b4f8f0e523d6dcfabfc2`.
- [Release run 43478754953, attempt 1](https://github.com/ptmt/anyring/actions/runs/43478754953), **success**; validation job **132069440932**, upload job **132078757570**.
- Marketing version **2.0**, archive/upload build **14.1**. Signed archive and export both succeeded. Apple explicitly reported **“Uploaded package is processing.”** and **“Upload succeeded.”** at `2026-11-13T18:23:38Z`.
- Hosted checks passed: 23 signing/configuration tests, simulator build, unsigned Release archive, 48 Swift Testing methods, two widget-render tests, six UI tests, and the separate Release HealthKit suite (two parameterized methods, ten cases). Full local Debug/Release evidence and independent review are in [HEALTHKIT-ASYNC.md](../docs/HEALTHKIT-ASYNC.md).
- All four original bundle IDs, team `49PJNAT2WC`, App Group, HealthKit, Watch app and Watch widget were validated and signed using the existing CI assets. Cleanup succeeded; GitHub reports zero artifacts. No signing/configuration changes were required.
- The push-only [run 43478755068](https://github.com/ptmt/anyring/actions/runs/43478755068) also succeeded and correctly skipped upload. Exactly one publish dispatch was issued; no retry or duplicate upload was needed.
- Latest verified Apple state is **processing started**, not processing completed or tester availability. App Store Connect browser access required login and had no saved credentials; no account access or new credentials were requested just to infer availability. Physical acceptance of this combined build remains outstanding; the owner had accepted 12.2's crash fix.

### Safe integration publication

Publication used the clean `/Users/tinyserve/Projects/anyring-integration-review` worktree on `review/laptop-async-integration`: fetch, verify the exact reviewed SHA and `origin/main` ancestry, normal non-force `git push origin HEAD:refs/heads/main`, read back the remote SHA, then one `gh workflow run testflight.yml -R ptmt/anyring --ref main -f publish=true`. Pushes only validate; the manual publish flag is required for signing/upload. Follow the exact run through completion before recording evidence in a documentation-only `[skip ci]` commit.

The original `/Users/tinyserve/Projects/anyring` dirty main was not checked out, reset, stashed or overwritten. Its HEAD and all 13 changed/untracked file hashes match `/Users/tinyserve/.hermes/backups/anyring-integration-20261113-184157/manifest.json` after publication. The combined release retains the laptop shape/palette/animation/sync/display-unit features and the async HealthKit implementation.

## Earlier Lock Screen widget release

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
- The owner subsequently confirmed that 12.2 no longer crashes on their iPhone.
  This acceptance does not establish the combined 14.1 build's device behavior.
  Do not ask for another crash report to identify the original failure: the
  supplied report has already been correlated.

## Device acceptance still required

After Apple processing and tester assignment, verify actual iPhone Lock Screen
installation, locked HealthKit/cache behavior, privacy/Always On, and paired Watch
configuration/complication updates. Automated rendering does not install a widget.
