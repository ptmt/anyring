import Foundation
import Combine

@MainActor
final class RingViewModel: ObservableObject, @preconcurrency CustomStringConvertible {
    @Published private(set) var progress = Progress.Empty
    @Published private(set) var error: Error?
    @Published private(set) var configuration: any ProviderConfiguration
    @Published private(set) var units: String
    @Published private(set) var isRefreshing = false
    var globalConfig: GlobalConfiguration
    var onConfigurationChanged: ((any ProviderConfiguration) -> Void)?

    var name: String { configuration.name }
    var fullName: String { "\(type(of: provider).name) / \(name)" }
    var providerDescription: String { type(of: provider).description }
    private let provider: any RingProvider
    private var refreshTask: AnyCancellable?
    private var refreshGeneration = 0

    init(provider: any RingProvider, globalConfig: GlobalConfiguration) {
        self.provider = provider
        self.globalConfig = globalConfig
        configuration = provider.config
        units = provider.config.units
        refresh()
    }

    func refresh() {
        refreshTask?.cancel()
        refreshGeneration += 1
        let generation = refreshGeneration
        isRefreshing = true
        error = nil
        units = configuration.units
        refreshTask = provider.calculateProgress(providerConfig: configuration, globalConfig: globalConfig)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self, self.refreshGeneration == generation else { return }
                self.isRefreshing = false
                if case .failure(let error) = completion { self.error = error }
            } receiveValue: { [weak self] value in
                guard let self, self.refreshGeneration == generation else { return }
                self.progress = value
            }
    }

    func update(config: any ProviderConfiguration) {
        guard config.minValue.isFinite, config.maxValue.isFinite else { return }
        provider.config = config
        configuration = config
        if let onConfigurationChanged { onConfigurationChanged(config) }
        else { provider.configPersistence.update(config: config) }
        refresh()
    }

    func updateFromSnapshot(snapshot: RingSnapshot) {
        var updated = configuration
        updated.appearance = RingAppearance(mainColor: snapshot.mainColor, gradient: snapshot.gradient,
                                             secondaryColor: snapshot.secondaryColor,
                                             outerGlow: snapshot.outerGlow, innerGlow: snapshot.innerGlow)
        update(config: updated)
    }

    func snapshot() -> RingSnapshot {
        RingSnapshot(progress: progress.normalized, mainColor: configuration.appearance.mainColor,
                     gradient: configuration.appearance.gradient,
                     secondaryColor: configuration.appearance.secondaryColor,
                     outerGlow: configuration.appearance.outerGlow,
                     innerGlow: configuration.appearance.innerGlow)
    }

    var description: String { progress.description + units }
}
