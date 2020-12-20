//
//  RingViewModel.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine

class RingViewModel: ObservableObject {
    @Published var progress: Progress? = nil
    @Published var error: Error? = nil
    
    private let provider: RingProvider
    private var cancellables = Set<AnyCancellable>()
    
    init(provider: RingProvider) {
        self.provider = provider
        defer {
        provider.calculateProgress().sink { [weak self] err in
            
        } receiveValue: { [weak self] value in
            self?.progress = value
        }.store(in: &cancellables)
        }
    }
}
