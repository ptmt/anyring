//
//  HealthKitDataSource.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine
import HealthKit


typealias HKSamples = [HKSample]

protocol HealthKitDataSource {
    func isAvailable() -> Bool
    func requestPermissions(permissions: Set<HKObjectType>) -> Future<Bool, Error>
//    func fetchSamples(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType) -> Future<HKSamples, Error>
    
    func fetchStatistics(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType, unit: HKUnit, aggregation: Aggregation) -> Future<Double, Error>
}
