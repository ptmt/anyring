//
//  RingProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import Foundation
import Combine
import HealthKit

protocol RingProvider {
    var name: String { get }
    var description: String { get }
    var units: String { get }
    
    var requiredHKPermission: HKSampleType? { get }
    func viewModel() -> RingViewModel
    func calculateProgress() -> AnyPublisher<Progress, Error>
}
