//
//  HealthKitDieatary.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 31.12.2020.
//

import Foundation
import HealthKit

// let res = a.map ( a => a.replaceAll(": HKQuantityTypeIdentifier", "").replaceAll("static let ", "") )
// function gen(sampleType, name, description) { return `diet(name: "${name}", description: "${description}", sampleType: .${sampleType}),\n` }
// var code = "["
// c.forEach((elem, index) => (index > 1 && index % 2 == 0 ? code+= gen(c[index-1], c[index].replace("A quantity sample type that measures the amount of ", "").replace(" consumed", ""), c[index]) : console.log("skip")) )
// c.map((elem, index) => (index > 1 && index % 2 == 0 ? `case .${c[index - 1]}: return HKObjectType.quantityType(forIdentifier: .${c[index - 1]})!` : '') ).filter(s => s).join("\n")

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

func diet(name: String, description: String, sampleType: HKObjectTypeCodable, units: HKUnitCodable = HKUnitCodable.mgrams, maxValue: Double = 100) -> HealthKitProvider.HealthKitConfiguration {
    HealthKitProvider.HealthKitConfiguration(
        name: name.capitalizingFirstLetter(),
        description: description,
        units: units,
        sampleType: sampleType,
        minValue: 0,
        maxValue: maxValue,
        aggregation: .sum
    )
}

let dietProviders = [diet(name: "biotin (vitamin B7)", description: "A quantity sample type that measures the amount of biotin (vitamin B7) consumed.", sampleType: .dietaryBiotin),diet(name: "calcium", description: "A quantity sample type that measures the amount of calcium consumed.", sampleType: .dietaryCalcium),diet(name: "carbohydrates", description: "A quantity sample type that measures the amount of carbohydrates consumed.", sampleType: .dietaryCarbohydrates),diet(name: "chloride", description: "A quantity sample type that measures the amount of chloride consumed.", sampleType: .dietaryChloride),diet(name: "cholesterol", description: "A quantity sample type that measures the amount of cholesterol consumed.", sampleType: .dietaryCholesterol),diet(name: "chromium", description: "A quantity sample type that measures the amount of chromium consumed.", sampleType: .dietaryChromium),diet(name: "copper", description: "A quantity sample type that measures the amount of copper consumed.", sampleType: .dietaryCopper),diet(name: "energy", description: "A quantity sample type that measures the amount of energy consumed.", sampleType: .dietaryEnergyConsumed),diet(name: "monounsaturated fat", description: "A quantity sample type that measures the amount of monounsaturated fat consumed.", sampleType: .dietaryFatMonounsaturated),diet(name: "polyunsaturated fat", description: "A quantity sample type that measures the amount of polyunsaturated fat consumed.", sampleType: .dietaryFatPolyunsaturated),diet(name: "saturated fat", description: "A quantity sample type that measures the amount of saturated fat consumed.", sampleType: .dietaryFatSaturated),diet(name: "Total Fat", description: "A quantity sample type that measures the total amount of fat consumed.", sampleType: .dietaryFatTotal),diet(name: "fiber", description: "A quantity sample type that measures the amount of fiber consumed.", sampleType: .dietaryFiber),diet(name: "folate (folic acid)", description: "A quantity sample type that measures the amount of folate (folic acid) consumed.", sampleType: .dietaryFolate),diet(name: "iodine", description: "A quantity sample type that measures the amount of iodine consumed.", sampleType: .dietaryIodine),diet(name: "iron", description: "A quantity sample type that measures the amount of iron consumed.", sampleType: .dietaryIron),diet(name: "magnesium", description: "A quantity sample type that measures the amount of magnesium consumed.", sampleType: .dietaryMagnesium),diet(name: "manganese", description: "A quantity sample type that measures the amount of manganese consumed.", sampleType: .dietaryManganese),diet(name: "molybdenum", description: "A quantity sample type that measures the amount of molybdenum consumed.", sampleType: .dietaryMolybdenum),diet(name: "niacin (vitamin B3)", description: "A quantity sample type that measures the amount of niacin (vitamin B3) consumed.", sampleType: .dietaryNiacin),diet(name: "pantothenic acid (vitamin B5)", description: "A quantity sample type that measures the amount of pantothenic acid (vitamin B5) consumed.", sampleType: .dietaryPantothenicAcid),diet(name: "phosphorus", description: "A quantity sample type that measures the amount of phosphorus consumed.", sampleType: .dietaryPhosphorus),diet(name: "potassium", description: "A quantity sample type that measures the amount of potassium consumed.", sampleType: .dietaryPotassium),diet(name: "protein", description: "A quantity sample type that measures the amount of protein consumed.", sampleType: .dietaryProtein),diet(name: "riboflavin (vitamin B2)", description: "A quantity sample type that measures the amount of riboflavin (vitamin B2) consumed.", sampleType: .dietaryRiboflavin),diet(name: "selenium", description: "A quantity sample type that measures the amount of selenium consumed.", sampleType: .dietarySelenium),diet(name: "sodium", description: "A quantity sample type that measures the amount of sodium consumed.", sampleType: .dietarySodium),diet(name: "sugar", description: "A quantity sample type that measures the amount of sugar consumed.", sampleType: .dietarySugar),diet(name: "thiamin (vitamin B1)", description: "A quantity sample type that measures the amount of thiamin (vitamin B1) consumed.", sampleType: .dietaryThiamin),diet(name: "vitamin A", description: "A quantity sample type that measures the amount of vitamin A consumed.", sampleType: .dietaryVitaminA),diet(name: "cyanocobalamin (vitamin B12)", description: "A quantity sample type that measures the amount of cyanocobalamin (vitamin B12) consumed.", sampleType: .dietaryVitaminB12),diet(name: "pyridoxine (vitamin B6)", description: "A quantity sample type that measures the amount of pyridoxine (vitamin B6) consumed.", sampleType: .dietaryVitaminB6),diet(name: "vitamin C", description: "A quantity sample type that measures the amount of vitamin C consumed.", sampleType: .dietaryVitaminC),diet(name: "vitamin D", description: "A quantity sample type that measures the amount of vitamin D consumed.", sampleType: .dietaryVitaminD),diet(name: "vitamin E", description: "A quantity sample type that measures the amount of vitamin E consumed.", sampleType: .dietaryVitaminE),diet(name: "vitamin K", description: "A quantity sample type that measures the amount of vitamin K consumed.", sampleType: .dietaryVitaminK),diet(name: "water", description: "A quantity sample type that measures the amount of water consumed.", sampleType: .dietaryWater, units: .milliliter),diet(name: "zinc", description: "A quantity sample type that measures the amount of zinc consumed.", sampleType: .dietaryZinc)
]
