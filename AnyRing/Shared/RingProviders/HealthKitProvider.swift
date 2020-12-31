//
//  ActivityProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import HealthKit
import Combine


let activityMinutesConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Activity Minutes",
    description: "A quantity sample type that measures the amount of time the user spent exercising.",
    units: HKUnitCodable.minute,
    sampleType: HKObjectTypeCodable.appleExerciseTime,
    minValue: 0,
    maxValue: 200,
    aggregation: .sum)

let hrvConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "HRV",
    units: HKUnitCodable.millisecond,
    sampleType: HKObjectTypeCodable.heartRateVariabilitySDNN,
    minValue: 0,
    maxValue: 100,
    aggregation: .max)

let hrConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Heart-rate",
    units: HKUnitCodable.countperminute,
    sampleType: HKObjectTypeCodable.heartRate,
    minValue: 0,
    maxValue: 100,
    reversed: true,
    aggregation: .min)

let healthKitProviders = [
    activityMinutesConfiguration,
    hrvConfiguration,
    hrConfiguration
]

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
    
    static let name = "HealthKit"
    static let description = """
    You can choose from pre-selected number of data sources. Some of them available only if you're using Apple Watch or alternatives.
    """
    
    private let dataSource: HealthKitDataSource
    
    let config: ProviderConfiguration
    let configPersistence: ConfigurationPersistence
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.dataSource = dataSource
        self.config = config as! Configuration
        self.configPersistence = configPersistence
    }
    
    func calculateProgress(providerConfig: ProviderConfiguration, globalConfig: GlobalConfiguration) -> AnyPublisher<Progress, Error> {
        return sum(numberOfDays: globalConfig.days).tryMap { (sum: Double) -> Progress in
            Progress(absolute: sum,
                     maxAbsolute: providerConfig.maxValue,
                     minAbsolute: providerConfig.minValue,
                     reversed: false)
        }.eraseToAnyPublisher()
    }
    
    private var cancellable: AnyCancellable?
    
    func viewModel(globalConfig: GlobalConfiguration) -> RingViewModel {
        RingViewModel(provider: self, globalConfig: globalConfig)
    }
    
    //private let hrvType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
    
    // var requiredHKPermission: HKSampleType? { hrvType }
    var healthKitParams: HealthKitConfiguration { (config as! Configuration).healthKitParams }
    
    private func sum(numberOfDays: Int) -> AnyPublisher<Double, Error> {
        
        return dataSource.fetchSamples(
            withStart: Date().addingTimeInterval(TimeInterval(-Double(numberOfDays) * secondsInDayApprox)),
            to: Date(),
            ofType: healthKitParams.sampleType.hkSampleType)
            .tryMap { results -> Double in
                
                let sumOfAllActivity = results.reduce(0) {(sum: Double, sample: HKSample) -> Double in
                    sum + (sample as! HKQuantitySample).quantity.doubleValue(for: self.healthKitParams.units.hkunit)
                }
                return sumOfAllActivity
            }.eraseToAnyPublisher()
    }
}


let secondsInDayApprox: Double = 60 * 60 * 24
