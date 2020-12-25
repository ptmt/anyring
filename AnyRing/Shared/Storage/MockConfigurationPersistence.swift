//
//  MockConfigurationPersistence.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 25.12.2020.
//

import Foundation

class MockConfigurationPersistence: ConfigurationPersistence {
    func persist(config: HardcodedConfiguration) {
        
    }
    func update(ring: Int, config: ProviderConfiguration) {
        
    }
    func restore() -> HardcodedConfiguration? {
        nil
    }
}
