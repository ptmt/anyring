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

    var isReversed: Bool { (configuration as? HealthKitProvider.Configuration).map { $0.workoutMetric == nil && $0.healthKitParams.reversed } ?? false }
    var direction: String { isReversed ? "Lower is better" : "Higher is better" }
    var comparison: String { isReversed ? "≤" : "≥" }
    var valueText: String { progress.empty && (isRefreshing || error != nil) ? "—" : format(progress.absolute) }
    /// The configured goal, never the reverse metric's starting baseline.
    var targetText: String { format(isReversed ? configuration.minValue : configuration.maxValue) }
    var goalText: String { "\(comparison) \(targetText) \(units)" }
    var overviewAccessibilityValue: String {
        ["\(valueText) \(units)", "Goal \(goalText)", direction, startingValueText,
         error?.localizedDescription].compactMap { $0 }.joined(separator: ", ")
    }
    var startingValueText: String? {
        guard isReversed || configuration.minValue != 0 else { return nil }
        return "From \(format(isReversed ? configuration.maxValue : configuration.minValue)) \(units)"
    }
    private func format(_ value: Double) -> String {
        guard value.isFinite else { return "—" }
        return value.formatted(.number.precision(.fractionLength(0...1)))
    }

    var name: String { configuration.displayName }
    var metricName: String { configuration.name }
    var fullName: String { "\(type(of: provider).name) / \(name)" }
    var providerDescription: String { type(of: provider).description }
    private let provider: any RingProvider
    private var refreshTask: Task<Void, Never>?
    private var refreshGeneration = 0

    init(provider: any RingProvider, globalConfig: GlobalConfiguration) {
        self.provider = provider
        self.globalConfig = globalConfig
        configuration = provider.config
        units = provider.config.units
        refresh()
    }

    func refresh() {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
           ProcessInfo.processInfo.arguments.contains("--metric-info-fixture"),
           ProcessInfo.processInfo.arguments.contains("--metric-info-preview") {
            setMetricInfoFixture(configuration.ring == .first ? "error" : "ready")
            return
        }
        #endif
        refreshTask?.cancel()
        refreshGeneration += 1
        let generation = refreshGeneration
        isRefreshing = true
        error = nil
        units = configuration.units
        let provider = provider
        let requested = configuration
        let global = globalConfig
        refreshTask = Task { [weak self] in
            do {
                let value = try await provider.calculateProgress(providerConfig: requested, globalConfig: global)
                guard !Task.isCancelled, let self, self.refreshGeneration == generation else { return }
                self.progress = value
                self.isRefreshing = false
            } catch {
                guard !Task.isCancelled, let self, self.refreshGeneration == generation else { return }
                self.error = error
                self.isRefreshing = false
            }
        }
    }

    #if targetEnvironment(simulator)
    /// Explicit synthetic presentation fixture; never compiled into device builds.
    func setMetricInfoFixture(_ state: String) {
        guard ProcessInfo.processInfo.arguments.contains("--metric-info-fixture"),
              ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return }
        refreshTask?.cancel()
        refreshGeneration += 1
        isRefreshing = state == "loading"
        error = state == "error" ? HealthDataError.noSamples : nil
        progress = state == "ready" ? Progress(absolute: configuration.ring == .third ? 52 : 12, maxAbsolute: configuration.maxValue,
                                               minAbsolute: configuration.minValue) : .Empty
    }
    #endif

    deinit { refreshTask?.cancel() }

    func update(config: any ProviderConfiguration) {
        guard config.minValue.isFinite, config.maxValue.isFinite else { return }
        let needsReading = !configuration.hasSameReadingConfiguration(as: config)
        if needsReading { progress = .Empty }
        applyMetadata(config)
        if let onConfigurationChanged { onConfigurationChanged(config) }
        else { provider.configPersistence.update(config: config) }
        if needsReading { refresh() }
    }

    /// The owner uses this only after verifying a label-only configuration change.
    func applyMetadata(_ config: any ProviderConfiguration) {
        provider.config = config
        configuration = config
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
