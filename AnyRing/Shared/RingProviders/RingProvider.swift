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
    static var name: String { get }
    static var description: String { get }
    var config: ProviderConfiguration { get set }
    var configPersistence: ConfigurationPersistence { get }
    

    func viewModel(globalConfig: GlobalConfiguration) -> RingViewModel
    func calculateProgress(providerConfig: ProviderConfiguration, globalConfig: GlobalConfiguration) -> AnyPublisher<Progress, Error>
}
