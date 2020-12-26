//
//  ProviderConfiguration.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 24.12.2020.
//

import Foundation
import Combine

protocol ProviderConfiguration: Codable {
    var provider: RingProvider.Type { get }
    
    var minValue: Double { get set }
    var maxValue: Double { get set }
    
    // split this into Appearance Configuration
    var mainColor: CodableColor { get set }
    var gradient: Bool { get set }
    var secondaryColor: CodableColor? { get set }
    var outerGlow: Bool { get set }
    var innerGlow: Bool { get set }
    
}

protocol HealthKitConfiguration: ProviderConfiguration {
}
