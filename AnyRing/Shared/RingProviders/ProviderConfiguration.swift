//
//  ProviderConfiguration.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 24.12.2020.
//

import Foundation
import Combine

enum RingID: Int, Codable {
    case first, second, third
}

protocol ProviderConfiguration: Codable {
    var provider: RingProvider.Type { get }
    var ring: RingID { get }
    var name: String { get set }
    
    var minValue: Double { get set }
    var maxValue: Double { get set }
    
    var appearance: RingAppearance { get set }
    
    var units: String { get }
}

