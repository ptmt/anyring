//
//  AnyRingViewModel.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 22.12.2020.
//

import Foundation
import Combine
import SwiftUI

class AnyRingViewModel: ObservableObject {
    #if targetEnvironment(simulator)
    // your simulator code
    let dataSource = DeviceHealthKitDataSource() // MockHealthKitDataSource()
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
    
    init() {
        defer { initViewModels() }
    }
    
    private func initViewModels() {
        let config = persistence.restore() ?? UserDefaultsConfigurationPersistence.defaultConfig
        globalConfig = config.global
        // instanitiate all ring providers
        providers = config.configs.map {
            return $0.provider.init(dataSource: dataSource, config: $0, configPersistence: persistence)
        }
        
        // collect all permissions for healthkit
        let permissions = providers.compactMap { ($0 as? HealthKitProvider)?.healthKitParams.sampleType.hkSampleType }
        
        initTask = dataSource.requestPermissions(permissions: Set(permissions))
            .receive(on: RunLoop.main)
            .sink { _ in } receiveValue: { [weak self] success in
                if (!success) {
                    self?.showingAlert = true
                } else if let self = self {
                    // instanitiate all view models
                    self.rings = RingWrapper(self.providers.map { $0.viewModel(globalConfig: self.globalConfig) })
                }
            }
    }
    
    func getSnapshots(completion: @escaping (RingWrapper<RingSnapshot>) -> Void) {
        snapshotTask = Publishers.MergeMany(providers.map { provider in
            provider.calculateProgress(providerConfig: provider.config, globalConfig: globalConfig).tryMap { RingSnapshot(progress: $0.normalized, mainColor: provider.config.appearance.mainColor.color) }
        })
        .collect()
        .sink { _ in
            
        } receiveValue: { result in
            completion(RingWrapper(result))
        }
    }
    
    func updatePeriod(days: Int) {
        self.globalConfig.days = days
        rings?.forEach { $0.globalConfig = self.globalConfig } 
        persistence.updateGlobal(globalConfig)
        rings?.forEach { $0.refresh() }
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

