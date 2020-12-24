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
   
    
    struct Configuration: ProviderConfiguration {
        var provider: RingProvider.Type { RestHRProvider.self }
        
        var minValue: Double
        var maxValue: Double
        var reversed: Bool
    }
    
    let name = "Min Heart Rate"
    let description = """
    This allows to track what was the lowest heart-rate at night for set period of days.
    """
    let units = "BPM"
    let requiredHKPermission: HKSampleType? = HKObjectType.quantityType(forIdentifier: .heartRate)!
    
    private let dataSource: HealthKitDataSource
    private let config: Configuration
    let numberOfNights: Double = 3
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration) {
        self.dataSource = dataSource
        self.config = config as! Configuration
    }
    
    private let configurationMax = 100.0
    private let configurationMin = 48.0
    private let reversed = true
    private let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        return fetchSamples().tryMap { (sample: HKSample?) -> Progress in
            Progress(absolute: (sample as! HKQuantitySample).quantity.doubleValue(for: self.unit),
                     maxAbsolute: self.config.maxValue,
                     minAbsolute: self.config.minValue,
                            reversed: self.reversed)
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
