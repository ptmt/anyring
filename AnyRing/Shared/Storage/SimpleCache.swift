import Foundation

struct CachedRingReading: Codable, Sendable {
    let rings: [RingSnapshot]
    let configuration: AnyRingConfig
    let date: Date
}

@MainActor
final class SimpleCache {
    static let key = "cache"
    static let configurationKey = "cache.configuration"
    static let readingKey = "cache.reading.v1"
    private let storage: UserDefaults

    init(storage: UserDefaults = UserDefaults(suiteName: UserDefaultsConfigurationPersistence.suiteName) ?? .standard) {
        self.storage = storage
    }

    func restoreReading(config: AnyRingConfig?) -> CachedRingReading? {
        guard let config, let data = storage.data(forKey: Self.readingKey),
              let reading = try? JSONDecoder().decode(CachedRingReading.self, from: data),
              reading.configuration == config, reading.rings.count == 3,
              reading.rings.allSatisfy({ $0.progress.isFinite }),
              reading.date <= Date() else { return nil }
        return reading
    }

    func restoreLastSnapshot(config: AnyRingConfig? = nil) -> RingWrapper<RingSnapshot>? {
        restoreReading(config: config).map { RingWrapper($0.rings) }
    }

    func store(lastSnapshot: RingWrapper<RingSnapshot>?, config: AnyRingConfig, date: Date = Date()) {
        guard let list = lastSnapshot?.list, list.allSatisfy({ $0.progress.isFinite }) else { return }
        let reading = CachedRingReading(rings: list, configuration: config, date: date)
        guard let data = try? JSONEncoder().encode(reading) else { return }
        // One value keeps the reading, its configuration and its real acquisition time together.
        storage.set(data, forKey: Self.readingKey)
    }
}
