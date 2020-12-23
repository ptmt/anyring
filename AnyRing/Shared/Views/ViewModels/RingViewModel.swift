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
    
    var units: String {
        provider.units
    }
    var name: String {
        provider.name
    }
    
    private let provider: RingProvider
    private var cancellables = Set<AnyCancellable>()
    
    init(provider: RingProvider) {
        self.provider = provider
        defer {
            refresh()
        }
    }
    
    func refresh() {
        provider.calculateProgress()
            .receive(on: RunLoop.main)
            .sink { _ in }
            receiveValue: { [weak self] value in
                self?.progress = value
            }.store(in: &cancellables)
    }
    
    var description: String {
        return progress.description + units
    }
}
