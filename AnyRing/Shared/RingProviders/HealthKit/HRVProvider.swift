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
    
    let name = "Max HRV"
    let description = """
    Last available value for Heart Rate Variability
    """
    let units = "MS"
    
    private let dataSource: HealthKitDataSource
    let numberOfNights: Double = 3
    
    init(dataSource: HealthKitDataSource) {
        self.dataSource = dataSource
    }
    
    private let configurationMax = 100.0
    private let configurationMin = 10.0
    private let reversed = false
    private let unit = HKUnit.secondUnit(with: .milli) // HKUnit.count().unitDivided(by: HKUnit.minute()) // HKUnit.secondUnit(with: .milli)
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        return fetchSamples().tryMap { (sample: HKSample?) -> Progress in
            Progress(absolute: (sample as! HKQuantitySample).quantity.doubleValue(for: self.unit),
                            maxAbsolute: self.configurationMax,
                            minAbsolute: self.configurationMin,
                            reversed: self.reversed)
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
                let minHR = results.min { (sample1, sample2) -> Bool in
                    (sample1 as! HKQuantitySample).quantity.doubleValue(for: self.unit) > (sample2 as! HKQuantitySample).quantity.doubleValue(for: self.unit)
                }
                return minHR
            }.eraseToAnyPublisher()
        return m
    }
}
