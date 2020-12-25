//
//  ActivityProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import HealthKit
import Combine

class ActivityProvider: RingProvider {
    
    struct Configuration: ProviderConfiguration {
        var provider: RingProvider.Type { ActivityProvider.self }
        
        var minValue: Double = 0
        var maxValue: Double = 200
        var mainColor: CodableColor
    }
    static var configurationType: ProviderConfiguration.Type = Configuration.self
    
    let name = "Total Activity"
    let description = """
    Sum of all activity minutes for a choosen number of days
    """
    let units = "min"
    
    private let dataSource: HealthKitDataSource
    let numberOfNights: Double = 3
    
    let config: ProviderConfiguration
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration) {
        self.dataSource = dataSource
        self.config = config as! Configuration
    }
    
    private let reversed = false
    private let unit = HKUnit.minute()
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        let config = self.config as! Configuration
        return sum().tryMap { (sum: Double) -> Progress in
            Progress(absolute: sum,
                     maxAbsolute: config.maxValue,
                        minAbsolute: config.minValue,
                            reversed: false)
        }.eraseToAnyPublisher()
    }
    
    func updateConfig(config: ProviderConfiguration) {
        
    }
    
    private var cancellable: AnyCancellable?
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    private let hrvType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
    
    var requiredHKPermission: HKSampleType? { hrvType }
    
    private func sum() -> AnyPublisher<Double, Error> {
        
        return dataSource.fetchSamples(
            withStart: Date().addingTimeInterval(TimeInterval(-numberOfNights * secondsInDayApprox)),
            to: Date(),
            ofType: hrvType)
            .tryMap { results -> Double in
                
                let sumOfAllActivity = results.reduce(0) {(sum: Double, sample: HKSample) -> Double in
                    sum + (sample as! HKQuantitySample).quantity.doubleValue(for: self.unit)
                }
                print("fetchSamples and sum for ActivityProvider", sumOfAllActivity)
                return sumOfAllActivity
            }.eraseToAnyPublisher()
    }
}
