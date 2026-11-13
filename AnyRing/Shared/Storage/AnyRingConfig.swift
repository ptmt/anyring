import Foundation

/// Keeps the original Config.v3 wire format so existing installations migrate in place.
struct AnyRingConfig: Codable, Equatable, Sendable {
    var configs: [any ProviderConfiguration]
    var global: GlobalConfiguration

    enum CodingKeys: String, CodingKey { case first, second, third, global }

    init(_ list: [any ProviderConfiguration], _ global: GlobalConfiguration) {
        precondition(list.count == 3)
        configs = list.sorted { $0.ring.rawValue < $1.ring.rawValue }
        self.global = global
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let first = try container.decode(HealthKitProvider.Configuration.self, forKey: .first).migratingLegacyConfiguration()
        let second = try container.decode(HealthKitProvider.Configuration.self, forKey: .second).migratingLegacyConfiguration()
        let third = try container.decode(HealthKitProvider.Configuration.self, forKey: .third).migratingLegacyConfiguration()
        global = try container.decode(GlobalConfiguration.self, forKey: .global)
        configs = [first, second, third]
        guard first.ring == .first, second.ring == .second, third.ring == .third,
              (1...365).contains(global.days),
              configs.allSatisfy({ $0.minValue.isFinite && $0.maxValue.isFinite }) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                   debugDescription: "Invalid ring configuration"))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        for (id, key) in [(RingID.first, CodingKeys.first), (.second, .second), (.third, .third)] {
            guard let config = configs.first(where: { $0.ring == id }) as? HealthKitProvider.Configuration else {
                throw EncodingError.invalidValue(configs, .init(codingPath: encoder.codingPath,
                                                                debugDescription: "Missing HealthKit ring"))
            }
            try container.encode(config, forKey: key)
        }
        try container.encode(global, forKey: .global)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let a = try? encoder.encode(lhs), let b = try? encoder.encode(rhs) else { return false }
        return a == b
    }
}

struct GlobalConfiguration: Codable, Equatable, Sendable {
    static let Default = GlobalConfiguration(days: 3)
    var days: Int
    var shape: RingShape = .roundedSquare

    enum CodingKeys: String, CodingKey { case days, shape }
    init(days: Int, shape: RingShape = .roundedSquare) {
        self.days = days
        self.shape = shape
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        days = try values.decode(Int.self, forKey: .days)
        shape = try values.decodeIfPresent(RingShape.self, forKey: .shape) ?? .roundedSquare
    }
}
