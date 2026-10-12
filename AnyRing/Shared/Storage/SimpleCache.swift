import Foundation

@MainActor
final class SimpleCache {
    static let key = "cache"
    static let configurationKey = "cache.configuration"
    private let storage: UserDefaults

    init(storage: UserDefaults = UserDefaults(suiteName: UserDefaultsConfigurationPersistence.suiteName) ?? .standard) {
        self.storage = storage
    }

    func restoreLastSnapshot(config: AnyRingConfig? = nil) -> RingWrapper<RingSnapshot>? {
        if let config {
            let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
            guard storage.data(forKey: Self.configurationKey) == (try? encoder.encode(config)) else { return nil }
        }
        guard let json = storage.data(forKey: Self.key),
              let decoded = try? JSONDecoder().decode([RingSnapshot].self, from: json), decoded.count == 3 else { return nil }
        return RingWrapper(decoded)
    }

    func store(lastSnapshot: RingWrapper<RingSnapshot>?, config: AnyRingConfig) {
        guard let list = lastSnapshot?.list else { return }
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(list), let configuration = try? encoder.encode(config) else { return }
        storage.set(data, forKey: Self.key)
        storage.set(configuration, forKey: Self.configurationKey)
    }
}
