//
//  MockHealthKitDataSource.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine
import HealthKit

class MockHealthKitDataSource: HealthKitDataSource {
    
    
    func isAvailable() -> Bool {
        return true
    }
    
    func requestPermissions(permissions: Set<HKObjectType>) -> Future<Bool, Error> {
        return Future() { promise in
            promise(.success(true))
        }
    }
    
    func fetchSamples(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType) -> Future<HKSamples, Error> {
        
        return Future() { promise in
            promise(.success([HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .heartRate)!, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 55), start: Date(), end: Date())]))
        }
    }
}
