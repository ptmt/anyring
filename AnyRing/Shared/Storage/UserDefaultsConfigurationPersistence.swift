//
//  UserDefaultsConfigurationPersistence.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 25.12.2020.
//

import Foundation

class UserDefaultsConfigurationPersistence: ConfigurationPersistence {
    static let key = "Config.v2"
//    static let defaultConfig = HardcodedConfiguration([
//        ActivityProvider.Configuration(minValue: 0, maxValue: 200, appearance: RingAppearance(mainColor: CodableColor(.green))),
//        RestHRProvider.Configuration(minValue: 40, maxValue: 70, appearance: RingAppearance(mainColor: CodableColor(.pink))),
//        HRVProvider.Configuration(minValue: 40, maxValue: 70, appearance: RingAppearance(mainColor: CodableColor(.purple)))
//    ], GlobalConfiguration(days: 3))
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
    func update(ring: Int, config: ProviderConfiguration) {
        precondition(ring <= 3)
        var currentConfig = lastReadValue ?? UserDefaultsConfigurationPersistence.defaultConfig
        currentConfig.configs[ring] = config
        persist(config: currentConfig)
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
            return nil
        }
    }
}
