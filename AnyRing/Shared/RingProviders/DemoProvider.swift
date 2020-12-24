//
//  DemoProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine
import HealthKit

class DemoProvider: RingProvider {

    struct Configuration: ProviderConfiguration {
        var provider: RingProvider.Type { DemoProvider.self }
        
        
    }
    static var configurationType: ProviderConfiguration.Type = Configuration.self
    
    var units: String = "KCAL"
    
    var name: String = "Demo"
    var description: String = "Demo provider"
    
    private let initValue: Double
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration) {
        self.name = "Demo"
        self.initValue = 20
        self.units = "KCAL"
    }
    
    init(_ name: String = "Demo", initValue: Double = 20, units: String = "KCAL") {
        self.name = name
        self.initValue = initValue
        self.units = units
    }
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    func requestNeededPermissions() -> Future<Bool, Error> {
        return Future() { promise in
            promise(.success(true))
        }
    }
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        Result<Progress, Error>.Publisher(.success(Progress(absolute: initValue, maxAbsolute: 100, minAbsolute: 0))).eraseToAnyPublisher()
    }
    
    var requiredHKPermission: HKSampleType? = nil
}
