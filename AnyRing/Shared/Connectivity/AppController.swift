import SwiftUI
import Combine
import WidgetKit

@MainActor
final class AppController: ObservableObject {
    let viewModel: AnyRingViewModel
    #if os(iOS) || os(watchOS)
    let connectivity: WatchConnectivityCoordinator
    #endif

    init() {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") &&
            !ProcessInfo.processInfo.arguments.contains("--preserve-test-settings") {
            let defaults = UserDefaults(suiteName: UserDefaultsConfigurationPersistence.suiteName) ?? .standard
            [UserDefaultsConfigurationPersistence.key, UserDefaultsConfigurationPersistence.snapshotKey,
             UserDefaultsConfigurationPersistence.lastSyncKey, UserDefaultsConfigurationPersistence.savedConfigurationsKey,
             SimpleCache.key, SimpleCache.configurationKey, SimpleCache.readingKey].forEach { defaults.removeObject(forKey: $0) }
            if ProcessInfo.processInfo.arguments.contains("--dashboard-density-fixture") {
                // Synthetic layout fixture: same three metrics/goals as the reported
                // screen, existing mock readings, and an intentionally EMPTY library.
                var fixture = UserDefaultsConfigurationPersistence.defaultConfig
                fixture.global = GlobalConfiguration(days: 3, shape: .squircle)
                fixture.configs[2] = HealthKitProvider.Configuration(ring: .third, healthKitParams: hrConfiguration,
                    appearance: fixture.configs[2].appearance)
                fixture.configs[1].maxValue = 15_000
                fixture.configs[2].minValue = 42
                fixture.configs[2].maxValue = 80
                if let data = try? JSONEncoder().encode(fixture) {
                    defaults.set(data, forKey: UserDefaultsConfigurationPersistence.key)
                }
            }
            if ProcessInfo.processInfo.arguments.contains("--legacy-template-fixture") {
                // Synthetic Config.v3 archive, not a fabricated pre-existing template library.
                var fixture = UserDefaultsConfigurationPersistence.defaultConfig
                fixture.global = GlobalConfiguration(days: 5, shape: .rectangular)
                fixture.configs[0] = HealthKitProvider.Configuration(ring: .first, healthKitParams: hrConfiguration,
                    appearance: RingAppearance(mainColor: CodableColor(.mint), outerGlow: true, innerGlow: true))
                fixture.configs[0].minValue = 35
                fixture.configs[0].maxValue = 60
                fixture.configs[0].customName = "Resting"
                let encoder = JSONEncoder(); encoder.userInfo[.legacyColorArchive] = true
                if let data = try? encoder.encode(fixture) { defaults.set(data, forKey: UserDefaultsConfigurationPersistence.key) }
            }
        }
        #endif
        let persistence = UserDefaultsConfigurationPersistence()
        let model = AnyRingViewModel(persistence: persistence)
        if persistence.restore() == nil { persistence.persist(config: model.config) }
        viewModel = model
        #if os(iOS) || os(watchOS)
        connectivity = WatchConnectivityCoordinator(persistence: persistence) { [weak model] snapshot in
            model?.apply(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        }
        model.onConfigurationChanged = { [weak connectivity] config in
            connectivity?.publish(config)
            WidgetCenter.shared.reloadAllTimelines()
        }
        connectivity.start()
        #else
        model.onConfigurationChanged = { _ in WidgetCenter.shared.reloadAllTimelines() }
        #endif
    }

    func becameActive() {
        viewModel.refresh()
        #if os(iOS) || os(watchOS)
        connectivity.refresh()
        #endif
        WidgetCenter.shared.reloadAllTimelines()
    }
}


#if os(iOS) || os(watchOS)
struct SyncStatusHeader: View {
    @ObservedObject var connectivity: WatchConnectivityCoordinator

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "arrow.triangle.2.circlepath")
            if let date = connectivity.lastSyncDate {
                Text("Last synced \(date, style: .relative) ago")
            } else {
                Text("Not synced yet")
            }
        }
        .font(.caption).foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("lastSync")
    }
}
#endif
