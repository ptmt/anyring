//
//  MockConfigurationPersistence.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 25.12.2020.
//

import Foundation

class MockConfigurationPersistence: ConfigurationPersistence {
    func persist(config: AnyRingConfig) {
        
    }
    func update(config: ProviderConfiguration) {
        
    }
    func restore() -> AnyRingConfig? {
        nil
    }
}
