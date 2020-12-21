//
//  RingProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import Combine

protocol RingProvider {
    var name: String { get }
    var description: String { get }
    var units: String { get }
    
    func requestNeededPermissions() -> Future<Bool, Error>
    func viewModel() -> RingViewModel
    func calculateProgress() -> AnyPublisher<Progress, Error>
}
