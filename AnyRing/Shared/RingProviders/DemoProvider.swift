//
//  DemoProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine
import HealthKit
import SwiftUI


class DemoProvider: RingProvider {
    
    struct Configuration: ProviderConfiguration {
        var name: String
        var provider: RingProvider.Type { DemoProvider.self }
        var ring: RingID
        var minValue: Double
        var maxValue: Double
        
        var appearance: RingAppearance
        var units: String
    }
    
    var units: String = "KCAL"
    static var name: String = "Demo"
    static let description: String = "Demo provider"
    var config: ProviderConfiguration
    let configPersistence: ConfigurationPersistence
    
    private let initValue: Double
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.initValue = 20
        self.config = config
        self.configPersistence = configPersistence
    }
    
    init(initValue: Double = 20,
         config: Configuration = Configuration(name: "Demo", ring: .first, minValue: 0, maxValue: 100, appearance: RingAppearance(mainColor: CodableColor(.orange)), units: "KCAL")) {
        self.initValue = initValue
        self.config = config
        self.configPersistence = MockConfigurationPersistence()
    }
    
    func viewModel(globalConfig: GlobalConfiguration) -> RingViewModel {
        RingViewModel(provider: self, globalConfig: globalConfig)
    }
    
    func requestNeededPermissions() -> Future<Bool, Error> {
        return Future() { promise in
            promise(.success(true))
        }
    }
    
    func calculateProgress(providerConfig: ProviderConfiguration, globalConfig: GlobalConfiguration) -> AnyPublisher<Progress, Error> {
        Result<Progress, Error>.Publisher(.success(Progress(absolute: initValue, maxAbsolute: providerConfig.maxValue, minAbsolute: providerConfig.minValue))).eraseToAnyPublisher()
    }
    
    var requiredHKPermission: HKSampleType? = nil
}
