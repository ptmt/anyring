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
    private let dataSource: HealthKitDataSource
    let name = "Rest Heart-rate provider"
    let numberOfNights: Double = 3
    
    init(dataSource: HealthKitDataSource) {
        self.dataSource = dataSource
    }
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        return fetchSamples().tryMap { (sample: HKSample?) -> Progress in
            Progress(absolute: 50, maxAbsolute: 45, units: "HR")
        }.eraseToAnyPublisher()
    }
    
    private var cancellable: AnyCancellable?
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    func fetchSamples() -> AnyPublisher<HKSample?, Error> {
        //        let calendar = NSCalendar.current
        //        let now = NSDate()
        //        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)
        //
        //        guard let startDate:NSDate = calendar.date(from: components) as NSDate? else { return }
        //        var dayComponent    = DateComponents()
        //        dayComponent.day    = 1
        //        let endDate:NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        //
        let unit = HKUnit.count().unitDivided(by: HKUnit.minute())
        let hr = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let m = dataSource.fetchSamples(
            withStart: Date().addingTimeInterval(TimeInterval(-numberOfNights * secondsInDayApprox)),
            to: Date(),
            ofType: hr)
            .tryMap { results -> HKSample? in
                let minHR = results.min { (sample1, sample2) -> Bool in
                    (sample1 as! HKQuantitySample).quantity.doubleValue(for: unit) < (sample2 as! HKQuantitySample).quantity.doubleValue(for: unit)
                }
                return minHR
            }.eraseToAnyPublisher()
        return m
    }
}

let secondsInDayApprox: Double = 60 * 60 * 24
