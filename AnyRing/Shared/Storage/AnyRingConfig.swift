//
//  AnyRingConfig.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 07.01.2021.
//

import Foundation

struct AnyRingConfig: Codable {
    var configs: [ProviderConfiguration]
    var global: GlobalConfiguration
    
    enum CodingKeys: String, CodingKey {
        case first
        case second
        case third
        case global
    }
    
    init(_ list: [ProviderConfiguration], _ global: GlobalConfiguration) {
        precondition(list.count == 3)
        configs = list.sorted(by: { (a, b) -> Bool in
            a.ring.rawValue < b.ring.rawValue
        })
        self.global = global
    }
    
    init(from decoder: Decoder) throws {
        
        // first ring is always
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let first = try container.decode(HealthKitProvider.Configuration.self, forKey: .first)
        let second = try container.decode(HealthKitProvider.Configuration.self, forKey: .second)
        let third = try container.decode(HealthKitProvider.Configuration.self, forKey: .third)
        let global = try container.decode(GlobalConfiguration.self, forKey: .global)
        
        self.configs = [first, second, third].sorted(by: { (a, b) -> Bool in
            a.ring.rawValue < b.ring.rawValue
        })
        self.global = global
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(configs.first { $0.ring == RingID.first } as? HealthKitProvider.Configuration, forKey: .first)
        try container.encode(configs.first { $0.ring == RingID.second } as? HealthKitProvider.Configuration, forKey: .second)
        try container.encode(configs.first { $0.ring == RingID.third } as? HealthKitProvider.Configuration, forKey: .third)
        try container.encode(global, forKey: .global)
    }
}

extension AnyRingConfig: Equatable {
    static func == (lhs: AnyRingConfig, rhs: AnyRingConfig) -> Bool {
        let lhsData = try? JSONEncoder().encode(lhs)
        let rhsData = try? JSONEncoder().encode(rhs)
        return lhsData == rhsData
    }
    
    
}

struct GlobalConfiguration: Codable, Equatable {
    static var Default = GlobalConfiguration(days: 3)
    var days: Int
}
