//
//  DataSource.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import HealthKit

let providerList = [RestHRProvider()]

class HealthKitDataSource {
    let healthStore = HKHealthStore()
    
    func isAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    func requestAllPermissions() {
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])
        healthStore.requestAuthorization(toShare: [], read: allTypes) { (success, error) in
            if !success {
                // Handle the error here.
            }
        }
    }
    
    func getTodaysHeartRates() {
        //predicate
        let calendar = NSCalendar.current
        let now = NSDate()
        let components = calendar.dateComponents([.year, .month, .day], from: now as Date)
        
        guard let startDate:NSDate = calendar.date(from: components) as NSDate? else { return }
        var dayComponent    = DateComponents()
        dayComponent.day    = 1
        let endDate:NSDate? = calendar.date(byAdding: dayComponent, to: startDate as Date) as NSDate?
        let predicate = HKQuery.predicateForSamples(withStart: startDate as Date, end: endDate as Date?, options: [])

        //descriptor
        let sortDescriptors = [
                                NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
                              ]
        
        let heartRateQuery = HKSampleQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: predicate, limit: 25, sortDescriptors: sortDescriptors, resultsHandler: { (query, results, error) in
            guard error == nil else { print("error"); return }

            print(results)
            // self.printHeartRateInfo(results: results)
        }) //eo-query
        
        healthStore.execute(heartRateQuery)
     }//eom
    
    func requestAllData() {
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])
        healthStore.requestAuthorization(toShare: [], read: allTypes) { (success, error) in
            if !success {
                // Handle the error here.
            }
        }
    }
}


//protocol Storage {
//    func get(key: String) -> String?
//}
//
//class UserDefaultsStorage: Storage {
//    let userDefaults = UserDefaults.standard
//    func get(key: String) -> String? {
//        return userDefaults.string(forKey: key)
//    }
//    func save(key: String, value: String) {
//        userDefaults.setValue(value, forKey: key)
//    }
//}
