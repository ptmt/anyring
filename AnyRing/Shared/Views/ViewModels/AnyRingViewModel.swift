import Foundation
import Combine
import SwiftUI
import HealthKit

@MainActor
protocol ConfigurationProvider {
    func config() -> AnyRingConfig
}

@MainActor
final class DefaultConfigurationProvider: ConfigurationProvider {
    func config() -> AnyRingConfig {
        UserDefaultsConfigurationPersistence().restore() ?? UserDefaultsConfigurationPersistence.defaultConfig
    }
}

@MainActor
final class AnyRingViewModel: ObservableObject {
    let dataSource: any HealthKitDataSource
    let persistence: UserDefaultsConfigurationPersistence
    @Published private(set) var showingAlert = false
    @Published private(set) var authorizationError: String?
    @Published private(set) var rings: RingWrapper<RingViewModel>?
    @Published private(set) var globalConfig: GlobalConfiguration
    @Published private(set) var config: AnyRingConfig
    var onConfigurationChanged: ((AnyRingConfig) -> Void)?

    private var permissionTask: AnyCancellable?
    private var providers: [any RingProvider] = []
    private var generation = 0
    private let requestAuthorization: Bool

    init(_ configurationProvider: (any ConfigurationProvider)? = nil,
         persistence: UserDefaultsConfigurationPersistence = UserDefaultsConfigurationPersistence(),
         dataSource: (any HealthKitDataSource)? = nil,
         requestAuthorization: Bool = true) {
        self.persistence = persistence
        self.requestAuthorization = requestAuthorization
        #if targetEnvironment(simulator)
        self.dataSource = dataSource ?? MockHealthKitDataSource()
        #else
        self.dataSource = dataSource ?? DeviceHealthKitDataSource()
        #endif
        let restored = configurationProvider?.config() ?? persistence.restore() ?? UserDefaultsConfigurationPersistence.defaultConfig
        config = restored
        globalConfig = restored.global
        installProviders()
    }

    private func installProviders() {
        permissionTask?.cancel()
        generation += 1
        let currentGeneration = generation
        showingAlert = false
        authorizationError = nil
        globalConfig = config.global
        providers = config.configs.map {
            $0.provider.init(dataSource: dataSource, config: $0, configPersistence: persistence)
        }
        let models = providers.map { $0.viewModel(globalConfig: globalConfig) }
        for model in models {
            model.onConfigurationChanged = { [weak self] changed in self?.updateRing(changed) }
        }
        rings = RingWrapper(models)
        let types = Set(config.configs.compactMap { ($0 as? HealthKitProvider.Configuration)?.healthKitParams.sampleType.hkSampleType })
        observeHealthChanges()
        guard requestAuthorization else { return }
        permissionTask = dataSource.requestPermissions(permissions: Set(types))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self, self.generation == currentGeneration else { return }
                if case .failure(let error) = result {
                    self.showingAlert = true
                    self.authorizationError = error.localizedDescription
                }
            } receiveValue: { [weak self] success in
                guard let self, self.generation == currentGeneration else { return }
                self.showingAlert = !success
                if success { self.refresh() }
            }
    }

    private func observeHealthChanges() {
        guard requestAuthorization, let device = dataSource as? DeviceHealthKitDataSource else { return }
        let types = Set(config.configs.compactMap { ($0 as? HealthKitProvider.Configuration)?.healthKitParams.sampleType.hkSampleType })
        device.observe(types: types) { [weak self] in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        rings?.forEach { $0.refresh() }
    }

    func updatePeriod(days: Int) {
        guard (1...365).contains(days), days != globalConfig.days else { return }
        var updated = config
        updated.global.days = days
        config = updated
        globalConfig = updated.global
        persistence.persist(config: updated)
        rings?.forEach { $0.globalConfig = updated.global; $0.refresh() }
        onConfigurationChanged?(updated)
    }

    private func updateRing(_ changed: any ProviderConfiguration) {
        guard let index = config.configs.firstIndex(where: { $0.ring == changed.ring }) else { return }
        let previousType = (config.configs[index] as? HealthKitProvider.Configuration)?.healthKitParams.sampleType
        let currentType = (changed as? HealthKitProvider.Configuration)?.healthKitParams.sampleType
        var updated = config
        updated.configs[index] = changed
        config = updated
        persistence.persist(config: updated)
        if previousType != currentType { observeHealthChanges() }
        onConfigurationChanged?(updated)
    }

    /// Install an accepted iPhone snapshot in one main-actor transaction, retaining its revision.
    func apply(_ snapshot: ConfigurationSnapshot) {
        persistence.persist(snapshot: snapshot)
        guard snapshot.config != config else { refresh(); return }
        config = snapshot.config
        installProviders()
    }

    func updateProviders() {
        config = persistence.restore() ?? config
        installProviders()
    }

    func handlePermissions(permissions: [HKObjectType]) -> Future<Bool, Error> {
        dataSource.requestPermissions(permissions: Set(permissions))
    }

    /// Each request owns its cancellable; widget timeline requests cannot cancel each other.
    func getSnapshots(completion: @escaping (RingWrapper<RingSnapshot>?, Error?) -> Void) {
        let currentConfig = config
        var task: AnyCancellable?
        task = Publishers.MergeMany(providers.map { provider in
            provider.calculateProgress(providerConfig: provider.config, globalConfig: currentConfig.global)
                .map { (provider.config.ring, RingSnapshot(progress: $0.normalized,
                       mainColor: provider.config.appearance.mainColor,
                       gradient: provider.config.appearance.gradient,
                       secondaryColor: provider.config.appearance.secondaryColor,
                       outerGlow: provider.config.appearance.outerGlow,
                       innerGlow: provider.config.appearance.innerGlow)) }
        })
        .collect()
        .receive(on: DispatchQueue.main)
        .sink { result in
            if case .failure(let error) = result { completion(nil, error) }
            task?.cancel(); task = nil
        } receiveValue: { snapshots in
            guard snapshots.count == 3 else { completion(nil, nil); return }
            completion(RingWrapper(snapshots.sorted { $0.0.rawValue < $1.0.rawValue }.map(\.1)), nil)
        }
    }
}

struct RingWrapper<T> {
    let list: [T]
    init(_ list: [T]) { precondition(list.count == 3); self.list = list }
    var first: T { list[0] }
    var second: T { list[1] }
    var third: T { list[2] }
    func forEach(_ body: (T) throws -> Void) rethrows { try list.forEach(body) }
}

extension RingWrapper: Sendable where T: Sendable {}
