//
//  DemoProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
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
    static let name: String = "Demo"
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
    
    @MainActor func viewModel(globalConfig: GlobalConfiguration) -> RingViewModel {
        RingViewModel(provider: self, globalConfig: globalConfig)
    }
    
    func calculateProgress(providerConfig: ProviderConfiguration, globalConfig: GlobalConfiguration) async throws -> Progress {
        try Task.checkCancellation()
        return Progress(absolute: initValue, maxAbsolute: providerConfig.maxValue, minAbsolute: providerConfig.minValue)
    }
    
    var requiredHKPermission: HKSampleType? = nil
}
