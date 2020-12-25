//
//  RingViewModel.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine

class RingViewModel: ObservableObject, CustomStringConvertible {
    @Published var progress: Progress = Progress.Empty
    @Published var error: Error? = nil
    @Published var configuration: ProviderConfiguration
    
    var units: String {
        provider.units
    }
    var name: String {
        provider.name
    }
    
    var providerDescription: String {
        provider.description
    }
    
    private let provider: RingProvider
    private var cancellables = Set<AnyCancellable>()
    
    init(provider: RingProvider) {
        self.provider = provider
        self.configuration = provider.config
        defer {
            refresh()
        }
    }
    
    func refresh() {
        provider.calculateProgress(config: configuration)
            .receive(on: RunLoop.main)
            .sink { _ in }
            receiveValue: { [weak self] value in
                self?.progress = value
            }.store(in: &cancellables)
    }
    
    func update(config: ProviderConfiguration) {
        var id = 0
        // we hardcoded the providers, remember
        if provider is RestHRProvider {
            id = 1
        }
        if provider is HRVProvider {
            id = 2
        }
        provider.configPersistence.update(ring: id, config: config)
        configuration = config
        refresh()
    }
    
    var description: String {
        return progress.description + units
    }
}
