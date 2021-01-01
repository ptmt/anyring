//
//  UserDefaultsConfigurationPersistence.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 25.12.2020.
//

import Foundation

class UserDefaultsConfigurationPersistence: ConfigurationPersistence {
    static let key = "Config.v3"
    static let defaultConfig = HardcodedConfiguration([
        HealthKitProvider.Configuration(ring: .first, healthKitParams: activityMinutesConfiguration, appearance: RingAppearance(mainColor: CodableColor(.green))),
        HealthKitProvider.Configuration(ring: .second, healthKitParams: hrvConfiguration, appearance: RingAppearance(mainColor: CodableColor(.pink))),
        HealthKitProvider.Configuration(ring: .third, healthKitParams: hrConfiguration, appearance: RingAppearance(mainColor: CodableColor(.purple))),
    ], GlobalConfiguration(days: 3))
    
    private let userDefaults = UserDefaults(suiteName: "group.49PJNAT2WC.com.potomushto.AnyRing")!
    
    private var lastReadValue: HardcodedConfiguration?
    
    func persist(config: HardcodedConfiguration) {
        if let json = try? JSONEncoder().encode(config) {
            lastReadValue = config
            userDefaults.setValue(json, forKey: UserDefaultsConfigurationPersistence.key)
        }
    }
    func update(config: ProviderConfiguration) {
        var currentConfig = lastReadValue ?? UserDefaultsConfigurationPersistence.defaultConfig
        if let index = (currentConfig.configs.firstIndex { $0.ring == config.ring }) {
            currentConfig.configs[index] = config
            persist(config: currentConfig)
        }
    }
    func updateGlobal(_ globalConfig: GlobalConfiguration) {
        var currentConfig = lastReadValue ?? UserDefaultsConfigurationPersistence.defaultConfig
        currentConfig.global = globalConfig
        persist(config: currentConfig)
    }
    func restore() -> HardcodedConfiguration? {
        if let json = userDefaults.value(forKey: UserDefaultsConfigurationPersistence.key) as? Data {
            let decoded = try? JSONDecoder().decode(HardcodedConfiguration.self, from: json)
            lastReadValue = decoded
            return decoded
        } else {
            print("Restoration failed")
            return nil
        }
    }
}
