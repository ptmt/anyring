//
//  RingProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import Combine
import HealthKit

protocol RingProvider {
    init(dataSource: HealthKitDataSource,
         config: ProviderConfiguration,
         configPersistence: ConfigurationPersistence)
    var name: String { get }
    var description: String { get }
    var units: String { get }
    var config: ProviderConfiguration { get }
    var configPersistence: ConfigurationPersistence { get }
    
    var requiredHKPermission: HKSampleType? { get }
    func viewModel() -> RingViewModel
    func calculateProgress(config: ProviderConfiguration) -> AnyPublisher<Progress, Error>
}
