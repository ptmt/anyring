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
    
    var minValue: Double { get }
    var maxValue: Double { get }
    
    // split this into Appearance Configuration
    var mainColor: CodableColor { get }
    
}

protocol HealthKitConfiguration: ProviderConfiguration {
}
