import Foundation
import OSLog

@MainActor
final class UserDefaultsConfigurationPersistence: ConfigurationPersistence {
    static let suiteName = "group.49PJNAT2WC.com.potomushto.AnyRing"
    static let key = "Config.v3"
    static let snapshotKey = "ConfigurationSnapshot.v1"
    static let defaultConfig = AnyRingConfig([
        HealthKitProvider.Configuration(ring: .first, healthKitParams: hrvConfiguration, appearance: RingAppearance(mainColor: CodableColor(.green))),
        HealthKitProvider.Configuration(ring: .second, healthKitParams: stepCount, appearance: RingAppearance(mainColor: CodableColor(.pink))),
        HealthKitProvider.Configuration(ring: .third, healthKitParams: activeEnergyBurned, appearance: RingAppearance(mainColor: CodableColor(.yellow)))
    ], .Default)

    private let userDefaults: UserDefaults
    private let logger = Logger(subsystem: "com.potomushto.AnyRing", category: "Configuration")

    init(userDefaults: UserDefaults = UserDefaults(suiteName: suiteName) ?? .standard) {
        self.userDefaults = userDefaults
    }

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
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(snapshot)
            let canonical = try encoder.encode(snapshot.config)
            let legacyEncoder = JSONEncoder()
            legacyEncoder.outputFormatting = .sortedKeys
            legacyEncoder.userInfo[.legacyColorArchive] = true
            let legacy = try legacyEncoder.encode(snapshot.config)
            // Store configuration and revision together so interrupted writes cannot mix generations.
            userDefaults.set(data, forKey: Self.snapshotKey)
            userDefaults.set(legacy, forKey: Self.key)
            if let cached = userDefaults.data(forKey: SimpleCache.configurationKey), cached != canonical {
                userDefaults.removeObject(forKey: SimpleCache.key)
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
