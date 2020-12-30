//
//  RestHRProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import HealthKit
import Combine

class RestHRProvider: RingProvider {
   
    struct Configuration: HealthKitConfiguration {
        var provider: RingProvider.Type { RestHRProvider.self }
        
        var minValue: Double = 46
        var maxValue: Double = 100
        
        var appearance: RingAppearance
    }
    
    let name = "Min Heart Rate"
    let description = """
    The lowest heart-rate at night.
    """
    let units = "BPM"
    let requiredHKPermission: HKSampleType? = HKObjectType.quantityType(forIdentifier: .heartRate)!
    
    private let dataSource: HealthKitDataSource
    let configPersistence: ConfigurationPersistence
    let config: ProviderConfiguration
    let numberOfNights: Double = 3
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.dataSource = dataSource
        self.config = config
        self.configPersistence = configPersistence
    }
    
    private let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
    
    func calculateProgress(config: ProviderConfiguration) -> AnyPublisher<Progress, Error> {
        return fetchSamples().tryMap { (sample: HKSample?) -> Progress in
            if let sample = sample as? HKQuantitySample {
                return Progress(absolute: sample.quantity.doubleValue(for: self.unit),
                     maxAbsolute: config.maxValue,
                     minAbsolute: config.minValue,
                            reversed: true)
            } else {
                return Progress(absolute: config.minValue, maxAbsolute: config.maxValue, minAbsolute: config.minValue)
            }
        }.eraseToAnyPublisher()
    }
    
    private var cancellable: AnyCancellable?
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    private func fetchSamples() -> AnyPublisher<HKSample?, Error> {
        let hr = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let m = dataSource.fetchSamples(
            withStart: Date().addingTimeInterval(TimeInterval(-numberOfNights * secondsInDayApprox)),
            to: Date(),
            ofType: hr)
            .tryMap { results -> HKSample? in
                let minHR = results.min { (sample1, sample2) -> Bool in
                    (sample1 as! HKQuantitySample).quantity.doubleValue(for: self.unit) < (sample2 as! HKQuantitySample).quantity.doubleValue(for: self.unit)
                }
                return minHR
            }.eraseToAnyPublisher()
        return m
    }
}

let secondsInDayApprox: Double = 60 * 60 * 24
