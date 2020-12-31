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
            if (sampleType == HKQuantityType.quantityType(forIdentifier: .heartRate)!) {
                promise(.success([HKQuantitySample(type: sampleType as! HKQuantityType, quantity: HKQuantity(unit: HKUnit.count().unitDivided(by: HKUnit.minute()), doubleValue: 55), start: Date(), end: Date())]))
                return
            }
            
            if (sampleType == HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!) {
                promise(.success([
                                HKQuantitySample(type: sampleType as! HKQuantityType, quantity: HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: 110), start: Date(), end: Date()),
                                HKQuantitySample(type: sampleType as! HKQuantityType, quantity: HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: 1), start: Date(), end: Date()),
                                HKQuantitySample(type: sampleType as! HKQuantityType, quantity: HKQuantity(unit: HKUnit.secondUnit(with: .milli), doubleValue: 50), start: Date(), end: Date())
                ]))
                return
            }
            
            if (sampleType == HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!) {
                promise(.success([HKQuantitySample(type: sampleType as! HKQuantityType, quantity: HKQuantity(unit: HKUnit.minute(), doubleValue: 110), start: Date(), end: Date())]))
                return
            }
            
            promise(.success([]))
        }
    }
}
