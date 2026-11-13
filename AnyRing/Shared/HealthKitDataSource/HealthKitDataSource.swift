//
//  HealthKitDataSource.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import HealthKit


@MainActor
protocol HealthKitDataSource {
    func isAvailable() -> Bool
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool
    func fetchStatistics(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType, unit: HKUnit, aggregation: Aggregation) async throws -> Double
}
