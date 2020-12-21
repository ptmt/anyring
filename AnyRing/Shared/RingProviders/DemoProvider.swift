//
//  DemoProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine

class DemoProvider: RingProvider {
    
    
    var units: String = "KCAL"
    
    var name: String = "Demo"
    var description: String = "Demo provider"
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    func requestNeededPermissions() -> Future<Bool, Error> {
        return Future() { promise in
            promise(.success(true))
        }
    }
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        Result<Progress, Error>.Publisher(.success(Progress(absolute: 20, maxAbsolute: 100, minAbsolute: 0))).eraseToAnyPublisher()
    }
    
    
}
