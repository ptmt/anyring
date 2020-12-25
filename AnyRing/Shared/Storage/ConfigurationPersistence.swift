//
//  Configuration.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 24.12.2020.
//

import Foundation

protocol ConfigurationPersistence {
    
}

class UserDefaultsConfigurationPersistence {
    static let key = "Config.v1"
    static let defaultConfig = HardcodedConfiguration([
        ActivityProvider.Configuration(minValue: 0, maxValue: 200, mainColor: CodableColor(.orange)),
        RestHRProvider.Configuration(minValue: 40, maxValue: 70, mainColor: CodableColor(.pink)),
        HRVProvider.Configuration(minValue: 40, maxValue: 70, mainColor: CodableColor(.purple))
    ])
    
    func persist(config: HardcodedConfiguration) {
        if let json = try? JSONEncoder().encode(config) {
            print(">> persist", String(data: json, encoding: .utf8))
            UserDefaults.standard.setValue(json, forKey: UserDefaultsConfigurationPersistence.key)
        }
    }
    func restore() -> HardcodedConfiguration? {
        if let json = UserDefaults.standard.value(forKey: UserDefaultsConfigurationPersistence.key) as? Data {
            let decoded = try? JSONDecoder().decode(HardcodedConfiguration.self, from: json)
            print(">> decoded", decoded)
            return decoded
        } else {
            return nil
        }
    }
}


struct HardcodedConfiguration: Codable {
    var configs: [ProviderConfiguration]
    
    enum CodingKeys: String, CodingKey {
        case first
        case second
        case third
    }
    
    init(_ list: [ProviderConfiguration]) {
        precondition(list.count == 3)
        configs = list
    }
    
    init(from decoder: Decoder) throws {
        // this is hardcoded implemention to save time after I realized of some limitation of Swift
        //
        
        // first ring is always
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let first = try container.decode(ActivityProvider.Configuration.self, forKey: .first)
        let second = try container.decode(RestHRProvider.Configuration.self, forKey: .second)
        let third = try container.decode(HRVProvider.Configuration.self, forKey: .third)
        
        self.configs = [first, second, third]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(configs.first as? ActivityProvider.Configuration, forKey: CodingKeys.first)
        try container.encode(configs[1] as? RestHRProvider.Configuration, forKey: CodingKeys.second)
        try container.encode(configs[2] as? HRVProvider.Configuration, forKey: CodingKeys.third)
    }
}
