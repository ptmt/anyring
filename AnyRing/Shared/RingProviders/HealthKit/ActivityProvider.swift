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
        
        var appearance: RingAppearance
    }
    static var configurationType: ProviderConfiguration.Type = Configuration.self
    
    let name = "Total Activity"
    let description = """
    Sum of all activity minutes for a choosen number of days
    """
    let units = "min"
    
    private let dataSource: HealthKitDataSource
    
    let config: ProviderConfiguration
    let configPersistence: ConfigurationPersistence
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.dataSource = dataSource
        self.config = config as! Configuration
        self.configPersistence = configPersistence
    }
    
    private let reversed = false
    private let unit = HKUnit.minute()
    
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
    
    private let hrvType = HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!
    
    var requiredHKPermission: HKSampleType? { hrvType }
    
    private func sum(numberOfDays: Int) -> AnyPublisher<Double, Error> {
        
        return dataSource.fetchSamples(
            withStart: Date().addingTimeInterval(TimeInterval(-Double(numberOfDays) * secondsInDayApprox)),
            to: Date(),
            ofType: hrvType)
            .tryMap { results -> Double in
                
                let sumOfAllActivity = results.reduce(0) {(sum: Double, sample: HKSample) -> Double in
                    sum + (sample as! HKQuantitySample).quantity.doubleValue(for: self.unit)
                }
                return sumOfAllActivity
            }.eraseToAnyPublisher()
    }
}
