//
//  HRVProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import HealthKit
import Combine

class HRVProvider: RingProvider {
    
    
    struct Configuration: HealthKitConfiguration {
        var provider: RingProvider.Type { HRVProvider.self }
        
        var minValue: Double = 0
        var maxValue: Double = 100
        
        var appearance: RingAppearance
    }
    
    let name = "Latest HRV"
    let description = """
    Last available value for Heart Rate Variability
    """
    let units = "MS"
    
    private let dataSource: HealthKitDataSource
    
    let numberOfNights: Double = 3
    let config: ProviderConfiguration
    let configPersistence: ConfigurationPersistence
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.dataSource = dataSource
        self.config = config
        self.configPersistence = configPersistence
    }
    
    private let unit = HKUnit.secondUnit(with: .milli)
  
    func calculateProgress(config: ProviderConfiguration) -> AnyPublisher<Progress, Error> {
        return fetchSamples().tryMap { (sample: HKSample?) -> Progress in
            if let sample = sample as? HKQuantitySample {
                return Progress(absolute: sample.quantity.doubleValue(for: self.unit),
                     maxAbsolute: config.maxValue,
                     minAbsolute: config.minValue,
                            reversed: false)
            } else {
                return Progress(absolute: config.minValue, maxAbsolute: config.maxValue, minAbsolute: config.minValue)
            }
        }.eraseToAnyPublisher()
    }
    
    private var cancellable: AnyCancellable?
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    private let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    
    var requiredHKPermission: HKSampleType? { hrvType }
    
    private func fetchSamples() -> AnyPublisher<HKSample?, Error> {
        let m = dataSource.fetchSamples(
            withStart: Date().addingTimeInterval(TimeInterval(-numberOfNights * secondsInDayApprox)),
            to: Date(),
            ofType: hrvType)
            .tryMap { results -> HKSample? in
                let latestHRV = results.min { (sample1, sample2) -> Bool in
                    (sample1 as! HKQuantitySample).endDate > (sample2 as! HKQuantitySample).endDate
                }
                return latestHRV
            }.eraseToAnyPublisher()
        return m
    }
}
