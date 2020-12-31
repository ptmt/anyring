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
    case percent
    case mgrams
    case grams
    
    var hkunit: HKUnit {
        switch(self) {
        case .minute: return HKUnit.minute()
        case .millisecond: return HKUnit.secondUnit(with: .milli)
        case .countperminute: return HKUnit.count().unitDivided(by: HKUnit.minute())
        case .percent: return HKUnit.percent()
        case .mgrams: return HKUnit.gramUnit(with: .milli)
        case .grams: return HKUnit.gram()
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
    case bloodAlcoholContent
    case dietaryCaffeine
    case dietaryBiotin
    case dietaryCalcium
    case dietaryCarbohydrates
    case dietaryChloride
    case dietaryCholesterol
    case dietaryChromium
    case dietaryCopper
    case dietaryEnergyConsumed
    case dietaryFatMonounsaturated
    case dietaryFatPolyunsaturated
    case dietaryFatSaturated
    case dietaryFatTotal
    case dietaryFiber
    case dietaryFolate
    case dietaryIodine
    case dietaryIron
    case dietaryMagnesium
    case dietaryManganese
    case dietaryMolybdenum
    case dietaryNiacin
    case dietaryPantothenicAcid
    case dietaryPhosphorus
    case dietaryPotassium
    case dietaryProtein
    case dietaryRiboflavin
    case dietarySelenium
    case dietarySodium
    case dietarySugar
    case dietaryThiamin
    case dietaryVitaminA
    case dietaryVitaminB12
    case dietaryVitaminB6
    case dietaryVitaminC
    case dietaryVitaminD
    case dietaryVitaminE
    case dietaryVitaminK
    case dietaryWater
    case dietaryZinc
    
    
    var hkSampleType: HKSampleType {
        switch(self) {
        case .appleExerciseTime: return HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
        case .heartRateVariabilitySDNN: return HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        case .heartRate: return HKObjectType.quantityType(forIdentifier: .heartRate)!
        case .bloodAlcoholContent: return HKObjectType.quantityType(forIdentifier: .bloodAlcoholContent)!
        case .dietaryCaffeine: return HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
        case .dietaryBiotin: return HKObjectType.quantityType(forIdentifier: .dietaryBiotin)!
        case .dietaryCalcium: return HKObjectType.quantityType(forIdentifier: .dietaryCalcium)!
        case .dietaryCarbohydrates: return HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)!
        case .dietaryChloride: return HKObjectType.quantityType(forIdentifier: .dietaryChloride)!
        case .dietaryCholesterol: return HKObjectType.quantityType(forIdentifier: .dietaryCholesterol)!
        case .dietaryChromium: return HKObjectType.quantityType(forIdentifier: .dietaryChromium)!
        case .dietaryCopper: return HKObjectType.quantityType(forIdentifier: .dietaryCopper)!
        case .dietaryEnergyConsumed: return HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        case .dietaryFatMonounsaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatMonounsaturated)!
        case .dietaryFatPolyunsaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatPolyunsaturated)!
        case .dietaryFatSaturated: return HKObjectType.quantityType(forIdentifier: .dietaryFatSaturated)!
        case .dietaryFatTotal: return HKObjectType.quantityType(forIdentifier: .dietaryFatTotal)!
        case .dietaryFiber: return HKObjectType.quantityType(forIdentifier: .dietaryFiber)!
        case .dietaryFolate: return HKObjectType.quantityType(forIdentifier: .dietaryFolate)!
        case .dietaryIodine: return HKObjectType.quantityType(forIdentifier: .dietaryIodine)!
        case .dietaryIron: return HKObjectType.quantityType(forIdentifier: .dietaryIron)!
        case .dietaryMagnesium: return HKObjectType.quantityType(forIdentifier: .dietaryMagnesium)!
        case .dietaryManganese: return HKObjectType.quantityType(forIdentifier: .dietaryManganese)!
        case .dietaryMolybdenum: return HKObjectType.quantityType(forIdentifier: .dietaryMolybdenum)!
        case .dietaryNiacin: return HKObjectType.quantityType(forIdentifier: .dietaryNiacin)!
        case .dietaryPantothenicAcid: return HKObjectType.quantityType(forIdentifier: .dietaryPantothenicAcid)!
        case .dietaryPhosphorus: return HKObjectType.quantityType(forIdentifier: .dietaryPhosphorus)!
        case .dietaryPotassium: return HKObjectType.quantityType(forIdentifier: .dietaryPotassium)!
        case .dietaryProtein: return HKObjectType.quantityType(forIdentifier: .dietaryProtein)!
        case .dietaryRiboflavin: return HKObjectType.quantityType(forIdentifier: .dietaryRiboflavin)!
        case .dietarySelenium: return HKObjectType.quantityType(forIdentifier: .dietarySelenium)!
        case .dietarySodium: return HKObjectType.quantityType(forIdentifier: .dietarySodium)!
        case .dietarySugar: return HKObjectType.quantityType(forIdentifier: .dietarySugar)!
        case .dietaryThiamin: return HKObjectType.quantityType(forIdentifier: .dietaryThiamin)!
        case .dietaryVitaminA: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminA)!
        case .dietaryVitaminB12: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB12)!
        case .dietaryVitaminB6: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminB6)!
        case .dietaryVitaminC: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminC)!
        case .dietaryVitaminD: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminD)!
        case .dietaryVitaminE: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminE)!
        case .dietaryVitaminK: return HKObjectType.quantityType(forIdentifier: .dietaryVitaminK)!
        case .dietaryWater: return HKObjectType.quantityType(forIdentifier: .dietaryWater)!
        case .dietaryZinc: return HKObjectType.quantityType(forIdentifier: .dietaryZinc)!
        }
    }
}
