//
//  UserDefaultsConfigurationPersistence.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 25.12.2020.
//

import Foundation

class UserDefaultsConfigurationPersistence: ConfigurationPersistence {
    static let key = "Config.v1"
    static let defaultConfig = HardcodedConfiguration([
        ActivityProvider.Configuration(minValue: 0, maxValue: 200, mainColor: CodableColor(.orange)),
        RestHRProvider.Configuration(minValue: 40, maxValue: 70, mainColor: CodableColor(.pink)),
        HRVProvider.Configuration(minValue: 40, maxValue: 70, mainColor: CodableColor(.purple))
    ])
    
    private let userDefaults = UserDefaults(suiteName: "group.com.potomushto.AnyRing")!
    
    private var lastReadValue: HardcodedConfiguration?
    
    func persist(config: HardcodedConfiguration) {
        if let json = try? JSONEncoder().encode(config) {
            lastReadValue = config
            userDefaults.setValue(json, forKey: UserDefaultsConfigurationPersistence.key)
        }
    }
    func update(ring: Int, config: ProviderConfiguration) {
        precondition(ring <= 3)
        var currentConfig = lastReadValue ?? UserDefaultsConfigurationPersistence.defaultConfig
        currentConfig.configs[ring] = config
        persist(config: currentConfig)
    }
    func restore() -> HardcodedConfiguration? {
        if let json = userDefaults.value(forKey: UserDefaultsConfigurationPersistence.key) as? Data {
            let decoded = try? JSONDecoder().decode(HardcodedConfiguration.self, from: json)
            lastReadValue = decoded
            return decoded
        } else {
            return nil
        }
    }
}
