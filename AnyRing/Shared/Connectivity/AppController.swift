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
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let defaults = UserDefaults(suiteName: UserDefaultsConfigurationPersistence.suiteName) ?? .standard
            [UserDefaultsConfigurationPersistence.key, UserDefaultsConfigurationPersistence.snapshotKey,
             SimpleCache.key, SimpleCache.configurationKey].forEach { defaults.removeObject(forKey: $0) }
        }
        #endif
        let persistence = UserDefaultsConfigurationPersistence()
        let model = AnyRingViewModel(persistence: persistence)
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
