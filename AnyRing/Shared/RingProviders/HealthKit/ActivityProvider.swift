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
    
    let name = "Total Activity"
    let description = """
    Sum of all activity minutes for a choosen periof of time
    """
    let units = "min"
    
    private let dataSource: HealthKitDataSource
    let numberOfNights: Double = 3
    
    init(dataSource: HealthKitDataSource) {
        self.dataSource = dataSource
    }
    
    private let configurationMax = 300.0
    private let configurationMin = 0.0
    private let reversed = false
    private let unit = HKUnit.minute()
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        return sum().tryMap { (sum: Double) -> Progress in
            Progress(absolute: sum,
                            maxAbsolute: self.configurationMax,
                            minAbsolute: self.configurationMin,
                            reversed: self.reversed)
        }.eraseToAnyPublisher()
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
                return sumOfAllActivity
            }.eraseToAnyPublisher()
    }
}
