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
            print(">> request allSatisfiy", Bundle.main.bundlePath)
            // We can't request the rights we it's an widget
            if Bundle.main.bundlePath.contains("Widget") {
                promise(.success(true))
            }
            let allSatisfy = permissions.allSatisfy {  self.healthStore.authorizationStatus(for: $0) == .sharingAuthorized }
            print(">> request allSatisfiy", allSatisfy)
            if (allSatisfy) {
                promise(.success(true))
                return
            }

            self.healthStore.requestAuthorization(toShare: [], read: permissions) { (success, error) in
                if let error = error {
                    print(">> request auth", error)
                    promise(.failure(error))
                } else {
                    print(">> request success")
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
