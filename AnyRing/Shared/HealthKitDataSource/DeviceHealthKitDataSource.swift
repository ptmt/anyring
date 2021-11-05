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
            // We can't request the rights we it's an widget
            if Bundle.main.bundlePath.contains("Widget") {
                promise(.success(true))
            }
            let allGranted = permissions.allSatisfy {  self.healthStore.authorizationStatus(for: $0) == .sharingAuthorized }
            if (allGranted) {
                promise(.success(true))
                return
            }
            
 

            self.healthStore.requestAuthorization(toShare: [], read: permissions) { (success, error) in
                
                if let error = error {
                    print("DeviceHealthKitDataSource: request auth", error)
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
    }
    
    func fetchStatistics(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType, unit: HKUnit, aggregation: Aggregation) -> Future<Double, Error> {
        
        return Future() { promise in
            
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
//
//            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortByDate], resultsHandler: { (query, results, error) in
//                if let error = error {
//                    promise(Result.failure(error))
//                } else {
//                    print(">> results", results)
//                    promise(Result.success(results!))
//                }
//            })
            
            
            var option: HKStatisticsOptions = .discreteAverage
            switch(aggregation) {
            case .sum: option = .cumulativeSum
            case .min: option = .discreteMin
            case .max: option = .discreteMin
            default: option = .discreteAverage
            }
            
           
            let query = HKStatisticsQuery(
                quantityType: (sampleType as! HKQuantityType),
                quantitySamplePredicate: predicate,
                options: option
            ) { _, result, _ in
                guard let result = result else {
                    promise(Result.success(0))
                    return
                }
                var aggregated: Double = 0
                switch(aggregation) {
                case .sum: aggregated = result.sumQuantity()?.doubleValue(for: unit) ?? 0
                case .avg: aggregated = result.averageQuantity()?.doubleValue(for: unit) ?? 0
                case .min: aggregated = result.minimumQuantity()?.doubleValue(for: unit) ?? 0
                case .max: aggregated = result.maximumQuantity()?.doubleValue(for: unit) ?? 0
                }
                promise(Result.success(aggregated))
                
            }
            
            self.healthStore.execute(query)
        }
    }
    
    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(
            quantityType: stepsQuantityType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        healthStore.execute(query)
    }
}
