//
//  Configuration.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 24.12.2020.
//

import Foundation

protocol ConfigurationPersistence {
    func persist(config: AnyRingConfig)
    func update(config: ProviderConfiguration)
    func restore() -> AnyRingConfig?
}


