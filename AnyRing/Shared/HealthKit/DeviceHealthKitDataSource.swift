//
//  DataSource.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import HealthKit
import Combine


class DeviceHealthKitDataSource: HealthKitDataSource {
    let healthStore = HKHealthStore()
    
    func isAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestPermissions(permissions: Set<HKObjectType>) -> Future<Bool, Error> {
    
        return Future() { promise in
            let allSatisfy = permissions.allSatisfy {  self.healthStore.authorizationStatus(for: $0) == .sharingAuthorized }
            if (allSatisfy) {
                promise(.success(true))
                return
            }

            self.healthStore.requestAuthorization(toShare: [], read: permissions) { (success, error) in
                if let error = error {
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
    }
    
    func fetchSamples(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType) -> Future<HKSamples, Error> {
        
        return Future() { promise in
            
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate as Date?, options: [])
            
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [], resultsHandler: { (query, results, error) in
                if let error = error {
                    promise(Result.failure(error))
                } else {
                    promise(Result.success(results!))
                }
            })
            
            self.healthStore.execute(query)
        }
    }
}
