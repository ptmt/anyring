//
//  CodableHealthKitStructs.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 31.12.2020.
//

import Foundation
import HealthKit

enum HKUnitCodable: String, Codable {
    case minute
    case millisecond
    case countperminute
    
    
    var hkunit: HKUnit {
        switch(self) {
        case .minute: return HKUnit.minute()
        case .millisecond: return HKUnit.secondUnit(with: .milli)
        case .countperminute: return HKUnit.count().unitDivided(by: HKUnit.minute())
        }
    }
    
    var description: String {
        "desc"
    }
}

enum HKObjectTypeCodable: String, Codable {
    case appleExerciseTime
    case heartRateVariabilitySDNN
    case heartRate
    
    var hkSampleType: HKSampleType {
        switch(self) {
        case .appleExerciseTime: return HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        case .heartRateVariabilitySDNN: return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        case .heartRate: return HKObjectType.quantityType(forIdentifier: .heartRate)!
        }
    }
}
