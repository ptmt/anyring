# iPhone native refresh cleanup

## Scope

Based on fresh `origin/main` `0c3c9214fcebc067801af18b22d08fe8162eb451`, preserving dark concentric icon source `32ef1a739f643f90c5329c3bafbeedfe47341046` and marketing version 2.0.

- Removed the iPhone toolbar Refresh button and `SyncStatusHeader` (`Not synced yet` / `Last synced … ago`). That header described configuration delivery, not a HealthKit reading time.
- Suppressed routine `Connecting`, `Ready for Apple Watch`, and `Settings synced` rows and removed the explanatory `Settings sync automatically` text. Kept Watch installation/failure guidance and all Health errors, Try Again, and Open Apple Health actions. No last-refresh label existed in `RingDashboard`; its tracking-period and metric/goal labels remain.
- Native Form pull-to-refresh calls the existing health refresh and the former toolbar's connectivity refresh. Automatic activation/authorization/HealthKit refresh, cache persistence and async generation fences are unchanged. No custom fixed indicator.
- Inspected shared MainScreen, RingDashboard, AppController and the Watch's separate ContentView before editing. Watch UI, SyncStatusHeader implementation, connectivity logic, settings, widgets/privacy and icon assets remain unchanged. Non-iOS toolbar behavior is retained.

## Verification

Xcode 27.2, isolated iPhone 18 Pro simulator, iOS 27.2. Synthetic fixtures only; no personal Health data or credentials captured.

- RED: actual Release UI assertions failed against the old refresh button and sync header. GREEN after removal.
- Actual drag gesture regression reads a simulator-only opt-in probe: the existing mock datasource query count increases by at least six (three ring queries plus three widget snapshot queries) and the production persisted matching reading date advances. Startup work must settle first; the probe itself only reads state. No probe is compiled into device builds.
- Negative control: leaving `.refreshable` present but disconnecting its body failed exactly `Pull must execute queries and replace the matching persisted reading`. Restored the real callback and reran the full Release suite.
- Full Release: **62 methods / 70 parameter-expanded executions passed**, including seven UI tests; zero failures/skips/runtime warnings. Existing cache/configuration/Watch/async-fence/privacy tests passed. 23 Python signing/configuration tests, shell syntax and diff whitespace checks passed.
- CI additionally runs the no-chrome and real-gesture tests in Release alongside the existing Release HealthKit callbacks; the existing full Debug suite and unsigned device archive remain.
- Inspected exported Release dashboard screenshot: no toolbar refresh or sync label, metric values/goals/period retained. Screenshot data is synthetic. Evidence under `~/.hermes/cache/scratch/anyring-native-refresh/` (`red-chrome`, `green-chrome`, `red-gesture`, `gesture`, `release-full` results/logs and `screenshots/`).

Physical HealthKit permission/reading behavior, paired Watch delivery and TestFlight processing/availability are separate from simulator verification. Release results are recorded in `ci/RELEASE.md` after actual Apple upload.
