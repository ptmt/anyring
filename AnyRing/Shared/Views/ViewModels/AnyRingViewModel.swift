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
    let dataSource = MockHealthKitDataSource()
    #else
    // your real device code
    let dataSource = DeviceHealthKitDataSource()
    #endif
    
    @Published var showingAlert = false
    @Published var rings: RingWrapper<RingViewModel>?
    
    private var initTask: AnyCancellable? = nil
    private var snapshotTask: AnyCancellable? = nil
    
    private var providers: [RingProvider] = []
    
    init() {
        defer { initViewModels() }
    }
    
    private func initViewModels() {
        // instanitiate all ring providers
        providers = [
            RestHRProvider(dataSource: dataSource),
            HRVProvider(dataSource: dataSource),
            ActivityProvider(dataSource: dataSource),
        ]
        
        // collect all permissions for healthkit
        let permissions = providers.compactMap { $0.requiredHKPermission }
        
        initTask = dataSource.requestPermissions(permissions: Set(permissions)).sink { _ in } receiveValue: { [weak self] success in
            if (!success) {
                self?.showingAlert = true
            } else if let self = self {
                // instanitiate all view models
                self.rings = RingWrapper(self.providers.map { $0.viewModel() })
            }
        }
    }
    
    func getSnapshots(completion: @escaping (RingWrapper<RingSnapshot>) -> Void) {
        snapshotTask = Publishers.MergeMany(providers.map { $0.calculateProgress() })
            .collect()
            .sink { _ in
            
        } receiveValue: { result in
            completion(RingWrapper(result.map({
                print(">>", $0)
                return RingSnapshot(progress: $0.normalized, color: Color.green)
            })))
        }
        
        
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
