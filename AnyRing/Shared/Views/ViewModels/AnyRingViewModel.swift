//
//  AnyRingViewModel.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 22.12.2020.
//

import Foundation
import Combine
import SwiftUI
import HealthKit

protocol ConfigurationProvider {
    func config() -> HardcodedConfiguration
}

class DefaultConfigurationProvider: ConfigurationProvider {
    private var persistence = UserDefaultsConfigurationPersistence()
    func config() -> HardcodedConfiguration {
        let config = persistence.restore() ?? UserDefaultsConfigurationPersistence.defaultConfig
        return config
    }
}

class AnyRingViewModel: ObservableObject {
    #if targetEnvironment(simulator)
    // your simulator code
    let dataSource = MockHealthKitDataSource()
    #else
    // your real device code
    let dataSource = DeviceHealthKitDataSource()
    #endif
    
    @Published var showingAlert = false
    @Published var rings: RingWrapper<RingViewModel>?
    @Published var globalConfig: GlobalConfiguration = GlobalConfiguration(days: 3)
    
    private var initTask: AnyCancellable? = nil
    private var snapshotTask: AnyCancellable? = nil
    
    private var providers: [RingProvider] = []
    private var persistence = UserDefaultsConfigurationPersistence()
    private let configurationProvider: ConfigurationProvider
    private(set) var config: HardcodedConfiguration = UserDefaultsConfigurationPersistence.defaultConfig
    
    init(_ configurationProvider: ConfigurationProvider = DefaultConfigurationProvider()) {
        self.configurationProvider = configurationProvider
        defer { initViewModels() }
    }
    
    private func initViewModels() {
        config = configurationProvider.config()
        globalConfig = config.global
        // instanitiate all ring providers
        providers = config.configs.map {
            return $0.provider.init(dataSource: dataSource, config: $0, configPersistence: persistence)
        }
        
        // collect all permissions for healthkit
        let permissions = providers.compactMap { (($0 as? HealthKitProvider)?.config as? HealthKitProvider.Configuration)?.healthKitParams.sampleType.hkSampleType }
        
        initTask = handlePermissions(permissions: permissions)
            .receive(on: RunLoop.main)
            .replaceError(with: false)
            .sink { _ in } receiveValue: { [weak self] success in
                if (!success) {
                    self?.showingAlert = true
                } else if let self = self {
                    // instanitiate all view models
                    self.rings = RingWrapper(self.providers.map { $0.viewModel(globalConfig: self.globalConfig) })
                }
            }
    }
    
    struct SnapshotWithId {
        var ring: RingID
        var snapshot: RingSnapshot
    }
    
    func getSnapshots(completion: @escaping (RingWrapper<RingSnapshot>) -> Void) {
        snapshotTask = Publishers.MergeMany(providers.map { provider in
            provider.calculateProgress(providerConfig: provider.config, globalConfig: globalConfig).tryMap {
                SnapshotWithId(ring: provider.config.ring, snapshot: RingSnapshot(progress: $0.normalized, mainColor: provider.config.appearance.mainColor.color)) }
        })
        .receive(on: RunLoop.main)
        .collect()
        .sink { _ in
            
        } receiveValue: { result in
            let sorted = result.sorted(by: { (a, b) -> Bool in
                a.ring.rawValue < b.ring.rawValue
            })
            completion(RingWrapper(sorted.map { $0.snapshot } ))
        }
    }
    
    func updatePeriod(days: Int) {
        self.globalConfig.days = days
        rings?.forEach { $0.globalConfig = self.globalConfig } 
        persistence.updateGlobal(globalConfig)
        rings?.forEach { $0.refresh() }
    }
    
    func updateProviders() {
        // re-create view models
        // by persist the config and re-create everything
        initViewModels()
    }
    
    func handlePermissions(permissions: [HKObjectType]) -> Future<Bool, Error> {
        return dataSource.requestPermissions(permissions: Set(permissions))
    }
}


struct RingWrapper<T> {
    
    private let list: [T]
    init(_ list: [T]) {
        precondition(list.count == 3)
        self.list = list
    }
    var first: T {
        list.first!
    }
    var second: T {
        list[1]
    }
    var third: T {
        list[2]
    }
    
    // why not Iterator?
    @inlinable func forEach(_ body: (T) throws -> Void) rethrows {
        try list.forEach(body)
    }
}

