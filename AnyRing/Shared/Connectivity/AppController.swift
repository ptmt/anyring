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
             UserDefaultsConfigurationPersistence.lastSyncKey,
             SimpleCache.key, SimpleCache.configurationKey, SimpleCache.readingKey].forEach { defaults.removeObject(forKey: $0) }
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
