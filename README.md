# AnyProgress

Three configurable Apple Health progress rings for iPhone, Apple Watch, and widgets. The app preserves metric selection, goals, reversed progress, aggregation, tracking periods, gradients, glows, and color palettes.

Requires iOS 26+, watchOS 26+, and Swift 6. The retained macOS target requires macOS 26; it shows an unavailable-data screen where Apple Health is unavailable. Open `AnyRing/AnyRing.xcodeproj` in Xcode 26 or later and select the `AnyRing (iOS)` scheme. Configure your development team for all app and widget targets before installing on devices.

## Architecture

- `Shared/Connectivity/AppController.swift` owns the model and connectivity service for the app's lifetime. Scene activation refreshes health values and settings independently of which screen is visible.
- The iPhone owns configuration. Every period, metric, goal, and appearance edit updates the in-memory model, persistence, and Watch sync source.
- `WatchConnectivityCoordinator` retains pending settings through activation, reconnects after Watch switching, uses application context for the latest saved state, sends live updates when reachable, and queues configuration-bearing background transfers for complications. Unchanged foreground refreshes do not enqueue another background transfer. The transport cancels obsolete queued configuration transfers and respects the complication transfer budget.
- The Watch installs its receive callback before activating the session, replays cached application context, requests current settings when reachable, and refreshes its own HealthKit queries on foreground activation. Every receive channel uses the same revision check; delayed updates cannot replace newer settings. Incoming settings are installed on the main actor and reload WidgetKit timelines.
- Configuration and its revision are persisted together in the existing app group. `Config.v3` and archived colors remain readable during migration. New snapshots use portable RGBA colors, and invalid legacy VO2/energy units are migrated. The original app and Watch app bundle identifiers and app group remain unchanged.
- The Watch uses a single app target and a WidgetKit extension. A small ClockKit migration bridge preserves the mapping for previously installed complications. Background connectivity tasks remain active while WatchConnectivity has pending content.
- Ring queries cancel superseded subscriptions. HealthKit failures are displayed instead of becoming zero values, and incompatible units return errors instead of raising conversion exceptions. Widgets never request authorization and only reuse cached rings for matching configuration.

Settings synchronize between devices; health readings come from each device's HealthKit store. Apple controls HealthKit replication, background transfer scheduling, and complication refresh budgets. The Watch remains usable with saved settings while the phone is unavailable.

## Verification

```sh
xcodebuild -project AnyRing/AnyRing.xcodeproj -scheme 'AnyRing (iOS)' \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

xcodebuild -project AnyRing/AnyRing.xcodeproj -scheme 'AnyRing (iOS)' \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
  CODE_SIGNING_ALLOWED=NO test
```

Validated with Xcode 27: device and simulator builds for the iPhone, Watch, and both WidgetKit extensions; the macOS build; 20 unit/regression tests; and 3 UI tests on iOS 26.2. Tests cover activation races, offline launch, reconnect requests, failed-send retry, out-of-order delivery, persistence, configuration edits, legacy migration, HealthKit aggregation, unit compatibility, navigation, metric search, and period persistence after relaunch.

### Paired-device checks

WatchConnectivity and complication delivery still require real-device validation. See Apple's [Watch Connectivity guidance](https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity) and [complication transfer documentation](https://developer.apple.com/documentation/watchconnectivity/wcsession/transfercurrentcomplicationuserinfo(_:)).

1. Upgrade an existing installation without deleting it; verify all three metrics, goals, colors, and period survive.
2. Change the period, a goal, and a color on iPhone; cold-launch the Watch app and check the final settings.
3. Disconnect the Watch, make several phone edits, reconnect, and launch the Watch. Confirm the latest edit wins and older queued updates never roll it back.
4. Launch the Watch while the phone is unavailable. Check saved settings, refreshed local health values, and the explicit offline status. Reconnect and use Refresh.
5. Keep a complication on the watch face, edit settings with the Watch app closed, and verify the complication refreshes. Check migration of an existing ClockKit complication.
6. If multiple Watches are paired, switch Watches and repeat synchronization. Also check denied Health permissions and an empty HealthKit store.

Sync failures are logged with subsystem `com.potomushto.AnyRing`, category `WatchSync`.
