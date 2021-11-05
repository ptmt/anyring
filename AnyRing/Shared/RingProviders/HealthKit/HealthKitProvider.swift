//
//  ActivityProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import HealthKit
import Combine


//let activityMinutesConfiguration = HealthKitProvider.HealthKitConfiguration(
//    name: "Activity Minutes",
//    description: "A quantity sample type that measures the amount of time the user spent exercising.",
//    units: HKUnitCodable.minute,
//    sampleType: HKObjectTypeCodable.appleExerciseTime,
//    minValue: 0,
//    maxValue: 200,
//    aggregation: .sum)

let hrvConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "HRV",
    description: "A quantity sample type that measures the standard deviation of heartbeat intervals.",
    units: HKUnitCodable.millisecond,
    sampleType: HKObjectTypeCodable.heartRateVariabilitySDNN,
    minValue: 0,
    maxValue: 100,
    aggregation: .max)

let hrConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Heart-rate",
    description: "A quantity sample type that measures the user’s heart rate.",
    units: HKUnitCodable.countperminute,
    sampleType: HKObjectTypeCodable.heartRate,
    minValue: 30,
    maxValue: 200,
    reversed: true,
    aggregation: .min)

let bloodAlcoholContentConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Blood Alchohol %",
    description: "A quantity sample type that measures the user’s blood alcohol content.",
    units: HKUnitCodable.percent,
    sampleType: HKObjectTypeCodable.bloodAlcoholContent,
    minValue: 0,
    maxValue: 100,
    aggregation: .max)

let dietaryCaffeineConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Caffeine",
    description: "A quantity sample type that measures the amount of caffeine consumed.",
    units: HKUnitCodable.mgrams,
    sampleType: HKObjectTypeCodable.dietaryCaffeine,
    minValue: 0,
    maxValue: 100,
    aggregation: .sum)

//let appleStandTime = HealthKitProvider.HealthKitConfiguration(
//    name: "Standing hours",
//    description: "A quantity sample type that measures the amount of time the user has spent standing.",
//    units: HKUnitCodable.minute,
//    sampleType: HKObjectTypeCodable.appleStandTime,
//    minValue: 0,
//    maxValue: 100,
//    aggregation: .sum)

let pushCount = HealthKitProvider.HealthKitConfiguration(
    name: "Pushes",
    description: "A quantity sample type that measures the number of pushes that the user has performed while using a wheelchair.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.pushCount,
    minValue: 0,
    maxValue: 400,
    aggregation: .sum)

let stepCount = HealthKitProvider.HealthKitConfiguration(
    name: "Step count",
    description: "A quantity sample type that measures the amount of time the user has spent standing.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.stepCount,
    minValue: 0,
    maxValue: 8000,
    aggregation: .sum)

//let distanceWalkingRunning = HealthKitProvider.HealthKitConfiguration(
//    name: "Distance",
//    description: "A quantity sample type that measures the distance the user has moved by walking or running.",
//    units: HKUnitCodable.meter,
//    sampleType: HKObjectTypeCodable.distanceWalkingRunning,
//    minValue: 0,
//    maxValue: 10000,
//    aggregation: .sum)

let distanceSwimming = HealthKitProvider.HealthKitConfiguration(
    name: "Swim",
    description: "A quantity sample type that measures the amount of time the user has spent standing.",
    units: HKUnitCodable.meter,
    sampleType: HKObjectTypeCodable.distanceSwimming,
    minValue: 0,
    maxValue: 2000,
    aggregation: .sum)

let flightsClimbed = HealthKitProvider.HealthKitConfiguration(
    name: "Flights Climbed",
    description: "A quantity sample type that measures the number flights of stairs that the user has climbed.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.flightsClimbed,
    minValue: 0,
    maxValue: 2000,
    aggregation: .sum)

let nikeFuel = HealthKitProvider.HealthKitConfiguration(
    name: "Nike Fuel",
    description: "A quantity sample type that measures the number of NikeFuel points the user has earned.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.nikeFuel,
    minValue: 0,
    maxValue: 2000,
    aggregation: .sum)

let vo2Max = HealthKitProvider.HealthKitConfiguration(
    name: "VO2Max",
    description: "A quantity sample that measures the maximal oxygen consumption during incremental exercise.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.vo2Max,
    minValue: 0,
    maxValue: 100,
    aggregation: .sum)

let activeEnergyBurned = HealthKitProvider.HealthKitConfiguration(
    name: "Active Energy",
    description: "A quantity sample type that measures the amount of active energy the user has burned.",
    units: HKUnitCodable.kilocalorie,
    sampleType: HKObjectTypeCodable.activeEnergyBurned,
    minValue: 0,
    maxValue: 1500,
    aggregation: .sum)

let distanceCycling = HealthKitProvider.HealthKitConfiguration(
    name: "Cycling",
    description: "A quantity sample type that measures the distance the user has moved by cycling.",
    units: HKUnitCodable.meter,
    sampleType: HKObjectTypeCodable.distanceCycling,
    minValue: 0,
    maxValue: 10000,
    aggregation: .sum)

let healthKitProviders = [
    stepCount,
    pushCount,
    distanceSwimming,
    flightsClimbed,
    nikeFuel,
    vo2Max,
    activeEnergyBurned,
    distanceCycling,
    hrvConfiguration,
    hrConfiguration,
    bloodAlcoholContentConfiguration,
    dietaryCaffeineConfiguration,
] + dietProviders

enum Aggregation: String, Codable {
    case avg = "Avg"
    case sum = "Sum"
    case min = "Min"
    case max = "Max"
}

class HealthKitProvider: RingProvider {
    
    struct HealthKitConfiguration: Codable, Hashable {
        var name: String
        var description: String
        var units: HKUnitCodable
        var sampleType: HKObjectTypeCodable
        var minValue: Double = 0
        var maxValue: Double = 200
        var reversed: Bool = false
        var aggregation: Aggregation = Aggregation.max
    }
    
    struct Configuration: ProviderConfiguration {
        var provider: RingProvider.Type { HealthKitProvider.self }
        var ring: RingID
        var healthKitParams: HealthKitConfiguration
        var appearance: RingAppearance
        
        var minValue: Double {
            get {
                healthKitParams.minValue
            }
            set {
                healthKitParams.minValue = newValue
            }
        }
        
        var maxValue: Double {
            get {
                healthKitParams.maxValue
            }
            set {
                healthKitParams.maxValue = newValue
            }
        }
        
        var name: String {
            get {
                healthKitParams.name
            }
            set {
                healthKitParams.name = newValue
            }
        }
        
        var units: String {
            let string: String = healthKitParams.units.hkunit.unitString
            return string.replacingOccurrences(of: "count/min", with: "bpm").uppercased()
        }
    }
    
    static var configurationType: ProviderConfiguration.Type = Configuration.self
    
    static let name = "Apple Health"
    static let description = """
    Some data sources are available only if you're using Apple Watch.
    """
    
    private let dataSource: HealthKitDataSource
    
    var config: ProviderConfiguration
    let configPersistence: ConfigurationPersistence
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.dataSource = dataSource
        self.config = config as! Configuration
        self.configPersistence = configPersistence
    }
    
    
    func calculateProgress(providerConfig: ProviderConfiguration, globalConfig: GlobalConfiguration) -> AnyPublisher<Progress, Error> {
        let healthKitParams = (providerConfig as! Configuration).healthKitParams
        return aggregate(numberOfDays: globalConfig.days,
                         sampleType: healthKitParams.sampleType.hkSampleType,
                         unit: healthKitParams.units.hkunit,
                         aggregation: healthKitParams.aggregation).tryMap { (aggregated: Double) -> Progress in
                            return Progress(absolute: aggregated,
                                     maxAbsolute: providerConfig.maxValue,
                                     minAbsolute: providerConfig.minValue,
                                     reversed: healthKitParams.reversed)
                         }.eraseToAnyPublisher()
    }
    
    private var cancellable: AnyCancellable?
    
    func viewModel(globalConfig: GlobalConfiguration) -> RingViewModel {
        RingViewModel(provider: self, globalConfig: globalConfig)
    }
    
    private func aggregate(numberOfDays: Int, sampleType: HKSampleType, unit: HKUnit, aggregation: Aggregation) -> AnyPublisher<Double, Error> {
        
        let calendar = Calendar.current
        // We calculate start of day, not the exact time
        let timeInDay = Date().addingTimeInterval(TimeInterval(-Double(numberOfDays - 1) * secondsInDayApprox))
        
        let startOfTheDay = calendar.startOfDay(for: timeInDay)
        
        return dataSource.fetchSamples(
            withStart: startOfTheDay,
            to: Date(),
            ofType: sampleType)
            .tryMap { results -> Double in
                switch(aggregation) {
                case .sum: return results.reduce(0) {(sum: Double, sample: HKSample) -> Double in
                    sum + (sample as! HKQuantitySample).quantity.doubleValue(for: unit)
                }
                case .avg:  return (results.reduce(0) {(sum: Double, sample: HKSample) -> Double in
                    sum + (sample as! HKQuantitySample).quantity.doubleValue(for: unit)
                }) / Double(results.count)
                case .min:  return (results.min { (sample1, sample2) -> Bool in
                    (sample1 as! HKQuantitySample).quantity.doubleValue(for: unit) < (sample2 as! HKQuantitySample).quantity.doubleValue(for: unit)
                } as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                case .max:  return (results.max { (sample1, sample2) -> Bool in
                    (sample1 as! HKQuantitySample).quantity.doubleValue(for: unit) < (sample2 as! HKQuantitySample).quantity.doubleValue(for: unit)
                } as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                }
            }.eraseToAnyPublisher()
    }
}


let secondsInDayApprox: Double = 60 * 60 * 24
