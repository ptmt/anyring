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
    var globalConfig: GlobalConfiguration
    
    var units: String {
        provider.config.units
    }
    
    var name: String {
        configuration.name
    }
    
    var fullName: String {
        "\(type(of: provider).name) / \(name)"
    }
    
    var providerDescription: String {
        type(of: provider).description
    }
    
    private let provider: RingProvider
    private var cancellables = Set<AnyCancellable>()
    
    init(provider: RingProvider, globalConfig: GlobalConfiguration) {
        self.provider = provider
        self.globalConfig = globalConfig
        self.configuration = provider.config
        defer {
            refresh()
        }
    }
    
    func refresh() {
        provider.calculateProgress(providerConfig: configuration, globalConfig: globalConfig)
            .receive(on: RunLoop.main)
            .sink { _ in }
            receiveValue: { [weak self] value in
                self?.progress = value
            }.store(in: &cancellables)
    }
    
    func update(config: ProviderConfiguration) {
        let id = config.ring.rawValue
        provider.configPersistence.update(ring: id, config: config)
        configuration = config
        refresh()
    }
    
    func updateFromSnapshot(snapshot: RingSnapshot) {
        let id = configuration.ring.rawValue
        var newConfig = configuration
        var newAppearance = configuration.appearance
        newAppearance.gradient = snapshot.gradient
        newAppearance.innerGlow = snapshot.innerGlow
        newAppearance.mainColor = CodableColor(snapshot.mainColor)
        if let secondaryColor = snapshot.secondaryColor {
            newAppearance.secondaryColor = CodableColor(secondaryColor)
        }
        newAppearance.outerGlow = snapshot.outerGlow
        newConfig.appearance = newAppearance
        provider.configPersistence.update(ring: id, config: newConfig)
        configuration = newConfig
        refresh()
    }
    
    func snapshot() -> RingSnapshot {
        .init(progress: progress.normalized,
              mainColor: configuration.appearance.mainColor.color,
              gradient: configuration.appearance.gradient,
              secondaryColor: configuration.appearance.secondaryColor?.color,
              outerGlow: configuration.appearance.outerGlow,
              innerGlow: configuration.appearance.innerGlow)
    }
    
    var description: String {
        return progress.description + units
    }
}
