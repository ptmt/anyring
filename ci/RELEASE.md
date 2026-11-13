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

Awaiting the authorized GitHub Actions publication. Local tests and an unsigned
archive are not evidence of signing or Apple upload. Publication evidence will
record the exact head SHA, run/jobs, build, and Apple result here.

## Device acceptance still required

After Apple processing and tester assignment, verify actual iPhone Lock Screen
installation, locked HealthKit/cache behavior, privacy/Always On, and paired Watch
configuration/complication updates. Automated rendering does not install a widget.
