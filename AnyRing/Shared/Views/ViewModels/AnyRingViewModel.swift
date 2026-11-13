import Foundation
import Combine
import SwiftUI
import HealthKit
import WidgetKit

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

    private var permissionTask: Task<Void, Never>?
    private var widgetTask: Task<Void, Never>?
    private var providers: [any RingProvider] = []
    private var generation = 0
    private var widgetGeneration = 0
    private let requestAuthorization: Bool

    init(_ configurationProvider: (any ConfigurationProvider)? = nil,
         persistence: UserDefaultsConfigurationPersistence = UserDefaultsConfigurationPersistence(),
         dataSource: (any HealthKitDataSource)? = nil,
         requestAuthorization: Bool = true) {
        self.persistence = persistence
        self.requestAuthorization = requestAuthorization
        #if targetEnvironment(simulator)
        self.dataSource = dataSource ?? (ProcessInfo.processInfo.arguments.contains("--ui-testing")
                                         ? MockHealthKitDataSource() : DeviceHealthKitDataSource(requireSamples: true))
        #else
        self.dataSource = dataSource ?? DeviceHealthKitDataSource(requireSamples: true)
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
        let dataSource = dataSource
        permissionTask = Task { [weak self] in
            do {
                let success = try await dataSource.requestPermissions(permissions: Set(types))
                guard !Task.isCancelled, let self, self.generation == currentGeneration else { return }
                self.showingAlert = !success
                if success { self.refresh() }
            } catch {
                guard !Task.isCancelled, let self, self.generation == currentGeneration else { return }
                self.showingAlert = true
                self.authorizationError = error.localizedDescription
            }
        }
    }

    deinit {
        permissionTask?.cancel()
        widgetTask?.cancel()
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
        if requestAuthorization { refreshWidgetSnapshot() }
    }

    /// Publish only a completed reading for the configuration that is still saved.
    func refreshWidgetSnapshot() {
        guard Bundle.main.bundleURL.pathExtension != "appex" else { return }
        widgetGeneration += 1
        let generation = widgetGeneration
        let requestedConfig = config
        widgetTask?.cancel()
        let providers = providers
        widgetTask = Task { [weak self] in
            // An unavailable reading keeps the last matching cache and its original date.
            guard let snapshots = try? await Self.getSnapshots(providers: providers, config: requestedConfig),
                  !Task.isCancelled, let self, self.widgetGeneration == generation,
                  self.config == requestedConfig,
                  self.persistence.restore() == requestedConfig else { return }
            self.persistence.widgetCache.store(lastSnapshot: snapshots, config: requestedConfig)
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    func updatePeriod(days: Int) {
        guard (1...365).contains(days), days != globalConfig.days else { return }
        var updated = config
        updated.global.days = days
        config = updated
        globalConfig = updated.global
        persistence.persist(config: updated)
        rings?.forEach { $0.globalConfig = updated.global; $0.refresh() }
        if requestAuthorization { refreshWidgetSnapshot() }
        onConfigurationChanged?(updated)
    }

    func updateShape(_ shape: RingShape) {
        guard shape != globalConfig.shape else { return }
        var updated = config
        updated.global.shape = shape
        config = updated
        globalConfig = updated.global
        persistence.persist(config: updated)
        rings?.forEach { $0.globalConfig = updated.global }
        if requestAuthorization { refreshWidgetSnapshot() }
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
        if requestAuthorization { refreshWidgetSnapshot() }
        onConfigurationChanged?(updated)
    }

    /// Install an accepted iPhone snapshot in one main-actor transaction, retaining its revision.
    func apply(_ snapshot: ConfigurationSnapshot) {
        persistence.persist(snapshot: snapshot)
        guard snapshot.config != config else { refresh(); return }
        config = snapshot.config
        installProviders()
        if requestAuthorization { refreshWidgetSnapshot() }
    }

    func updateProviders() {
        config = persistence.restore() ?? config
        installProviders()
    }

    func handlePermissions(permissions: [HKObjectType]) async throws -> Bool {
        try await dataSource.requestPermissions(permissions: Set(permissions))
    }

    /// Each caller owns its child queries; concurrent widget requests remain independent.
    func getSnapshots() async throws -> RingWrapper<RingSnapshot> {
        try await Self.getSnapshots(providers: providers, config: config)
    }

    private static func getSnapshots(providers: [any RingProvider], config: AnyRingConfig) async throws -> RingWrapper<RingSnapshot> {
        try await withThrowingTaskGroup(of: (RingID, RingSnapshot).self) { group in
            for (provider, requested) in zip(providers, config.configs) {
                group.addTask {
                    let progress = try await provider.calculateProgress(providerConfig: requested, globalConfig: config.global)
                    return (requested.ring, RingSnapshot(progress: progress.normalized,
                        mainColor: requested.appearance.mainColor,
                        gradient: requested.appearance.gradient,
                        secondaryColor: requested.appearance.secondaryColor,
                        outerGlow: requested.appearance.outerGlow,
                        innerGlow: requested.appearance.innerGlow))
                }
            }
            var snapshots: [(RingID, RingSnapshot)] = []
            for try await snapshot in group { snapshots.append(snapshot) }
            try Task.checkCancellation()
            return RingWrapper(snapshots.sorted { $0.0.rawValue < $1.0.rawValue }.map(\.1))
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
