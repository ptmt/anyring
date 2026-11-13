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

## Lock Screen widgets

The existing `RingWidgetExtension` supplies circular, rectangular, and inline Lock Screen widgets alongside the Home Screen widgets. No separate extension or Live Activity is required. The app's existing iOS 26 minimum is unchanged.

1. Open AnyProgress, allow read access to your chosen Apple Health metrics, and configure the three rings and tracking period.
2. Touch and hold the iPhone Lock Screen, choose **Customize → Lock Screen**, then tap the widget area below the clock and choose **AnyProgress**. Circular and rectangular widgets show all three rings. Tap the date area above the clock to add the inline widget, which shows the first ring's name and percentage.
3. Edit metrics, goals, reversed progress, colors, and period in the app. Widgets use the same saved settings, not a separate widget configuration. Tap the inline widget to open Ring 1; other widgets open the overview.

The extension reads HealthKit without asking for permission. Completed readings are cached with their matching configuration and original reading time in `group.49PJNAT2WC.com.potomushto.AnyRing`. Missing settings, unreadable samples, or a changed goal without a matching reading show **Open AnyProgress**, never demonstration progress. A genuine recorded zero remains 0%; over-goal percentages remain above 100%. The reading time is available in the accessibility summary. Failed locked-device queries can reuse the last matching reading without relabeling it as fresh.

Health changes, app refreshes, and settings edits request timeline reloads. A timeline also requests another update after 30 minutes; iOS controls the actual refresh budget, so this is not continuous or guaranteed real-time tracking. Health data may be inaccessible while locked. Sensitive text **and ring geometry** are replaced with a generic icon when the system requests privacy redaction; visibility also depends on the device's Lock Screen/Always On privacy settings.

### Build and device setup

Keep the app, widget, Watch bundle identifiers, existing team, HealthKit capability, and shared App Group aligned. Device installation requires valid provisioning profiles for those existing identifiers and membership in the owning team; do not create replacement identifiers or groups just to make signing pass. Simulator ad-hoc signing verifies builds and UI but not physical-device App Group entitlement enforcement.

Verified locally with Xcode 27.2 / iPhone 18 Pro iOS 27.2: 31 passing tests (25 unit/regression tests, 2 widget-render/privacy tests, 4 UI tests), Release simulator build, unsigned device build including the embedded phone/Watch widget extensions, and accessory-view renders for data/empty/private states. Device-signed installation is currently blocked by missing provisioning profiles for the original identifiers. Actual Lock Screen installation, HealthKit sharing while locked, Always On behavior, and refresh timing still need an owner-provisioned physical iPhone check. The automated renderer runs the production SwiftUI widget view at accessory sizes; it does not install a widget on the Lock Screen.

Apple references: [accessory widgets](https://developer.apple.com/documentation/widgetkit/creating-accessory-widgets-and-watch-complications), [refresh budgets](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date), [privacy-sensitive views](https://developer.apple.com/documentation/swiftui/view/privacysensitive(_:)).

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
