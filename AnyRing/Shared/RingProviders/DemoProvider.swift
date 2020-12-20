//
//  DemoProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine

class DemoProvider: RingProvider {
    var name: String = "Demo"
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        Result<Progress, Error>.Publisher(.success(Progress(absolute: 20, maxAbsolute: 100, units: "Unit"))).eraseToAnyPublisher()
    }
    
    
}
