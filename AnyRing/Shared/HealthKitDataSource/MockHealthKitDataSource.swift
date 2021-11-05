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
    
    func fetchStatistics(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType, unit: HKUnit, aggregation: Aggregation) -> Future<Double, Error> {
        
        return Future() { promise in
            if (sampleType == HKQuantityType.quantityType(forIdentifier: .heartRate)!) {
                promise(.success(55))
                return
            }
            
            if (sampleType == HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!) {
                promise(.success(110))
                return
            }
            
            if (sampleType == HKQuantityType.quantityType(forIdentifier: .appleStandTime)!) {
                promise(.success(8))
                return
            }
            
            if (sampleType == HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!) {
                promise(.success(1100))
                return
            }
            
            if (sampleType == HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!) {
                promise(.success(110))
                return
            }
            
            if (sampleType == HKObjectType.quantityType(forIdentifier: .stepCount)!) {
                promise(.success(5100))
                return
            }
            
            promise(.success(0))
        }
    }
}
