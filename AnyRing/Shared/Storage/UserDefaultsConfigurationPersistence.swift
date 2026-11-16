import Foundation
import OSLog

@MainActor
final class UserDefaultsConfigurationPersistence: ConfigurationPersistence {
    static let suiteName = "group.49PJNAT2WC.com.potomushto.AnyRing"
    static let key = "Config.v3"
    static let snapshotKey = "ConfigurationSnapshot.v1"
    static let lastSyncKey = "Sync.lastConfirmedDate"
    static let defaultConfig = AnyRingConfig([
        HealthKitProvider.Configuration(ring: .first, healthKitParams: hrvConfiguration, appearance: RingAppearance(mainColor: CodableColor(.green))),
        HealthKitProvider.Configuration(ring: .second, healthKitParams: stepCount, appearance: RingAppearance(mainColor: CodableColor(.pink))),
        HealthKitProvider.Configuration(ring: .third, healthKitParams: activeEnergyBurned, appearance: RingAppearance(mainColor: CodableColor(.yellow)))
    ], .Default)

    var widgetCache: SimpleCache { SimpleCache(storage: userDefaults) }

    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.potomushto.AnyRing", category: "Configuration")

    init(userDefaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard) {
        self.userDefaults = userDefaults
    }

    // Additive library: never repurpose Config.v3 or the Watch configuration snapshot.
    static let savedConfigurationsKey = "SavedConfigurations.v1"

    func restoreSavedConfigurations() throws -> [SavedConfiguration] {
        guard let value = userDefaults.object(forKey: Self.savedConfigurationsKey) else { return [] }
        guard let data = value as? Data else { throw SavedConfigurationError.unreadable }
        let records = try JSONDecoder().decode([SavedConfiguration].self, from: data)
        guard Set(records.map(\.id)).count == records.count else { throw SavedConfigurationError.unreadable }
        return records
    }

    func persistSavedConfigurations(_ records: [SavedConfiguration]) throws {
        // Refuse to replace unreadable records with an empty/default library.
        _ = try restoreSavedConfigurations()
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = try encoder.encode(records)
        userDefaults.set(data, forKey: Self.savedConfigurationsKey)
    }

    func restoreLastSyncDate() -> Date? { userDefaults.object(forKey: Self.lastSyncKey) as? Date }
    func persistLastSyncDate(_ date: Date) { userDefaults.set(date, forKey: Self.lastSyncKey) }

    func restoreSnapshot() -> ConfigurationSnapshot? {
        guard let data = userDefaults.data(forKey: Self.snapshotKey) else { return nil }
        do { return try JSONDecoder().decode(ConfigurationSnapshot.self, from: data) }
        catch { logger.error("Cannot read configuration snapshot: \(error.localizedDescription)"); return nil }
    }

    func restore() -> AnyRingConfig? {
        if let snapshot = restoreSnapshot() { return snapshot.config }
        guard let data = userDefaults.data(forKey: Self.key) else { return nil }
        do { return try JSONDecoder().decode(AnyRingConfig.self, from: data) }
        catch { logger.error("Cannot read legacy configuration: \(error.localizedDescription)"); return nil }
    }

    func persist(config: AnyRingConfig) {
        let previous = restoreSnapshot()
        if previous?.config == config { return }
        let revision = max(Date().timeIntervalSince1970, (previous?.revision ?? 0) + 0.001)
        persist(snapshot: ConfigurationSnapshot(config: config, revision: revision))
    }

    func persist(snapshot: ConfigurationSnapshot) {
        let previousConfig = restore()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(snapshot)
            let legacyEncoder = JSONEncoder()
            legacyEncoder.outputFormatting = .sortedKeys
            legacyEncoder.userInfo[.legacyColorArchive] = true
            let legacy = try legacyEncoder.encode(snapshot.config)
            // Store configuration and revision together so interrupted writes cannot mix generations.
            userDefaults.set(data, forKey: Self.snapshotKey)
            userDefaults.set(legacy, forKey: Self.key)
            if previousConfig != snapshot.config {
                let reading = widgetCache.restoreReading(config: previousConfig)
                userDefaults.removeObject(forKey: SimpleCache.key)
                userDefaults.removeObject(forKey: SimpleCache.configurationKey)
                userDefaults.removeObject(forKey: SimpleCache.readingKey)
                if let previousConfig, previousConfig.hasSameReadingConfiguration(as: snapshot.config), let reading {
                    // Rename the metadata, not the acquisition date or progress.
                    widgetCache.store(lastSnapshot: RingWrapper(reading.rings), config: snapshot.config, date: reading.date)
                }
            }
        } catch { logger.error("Cannot save configuration: \(error.localizedDescription)") }
    }

    func update(config: any ProviderConfiguration) {
        var current = restore() ?? Self.defaultConfig
        guard let index = current.configs.firstIndex(where: { $0.ring == config.ring }) else { return }
        current.configs[index] = config
        persist(config: current)
    }

    func updateGlobal(_ globalConfig: GlobalConfiguration) {
        var current = restore() ?? Self.defaultConfig
        current.global = globalConfig
        persist(config: current)
    }
}
