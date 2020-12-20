//
//  RingProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import Combine

struct Progress {
    let absolute: Double
    let maxAbsolute: Double
    let units: String
    
    var progress: Double {
        absolute / maxAbsolute
    }
}

protocol RingProvider {
    var name: String { get }
    
    func viewModel() -> RingViewModel
    func calculateProgress() -> AnyPublisher<Progress, Error>
}
