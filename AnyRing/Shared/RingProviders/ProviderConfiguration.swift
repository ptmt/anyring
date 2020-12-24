//
//  ProviderConfiguration.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 24.12.2020.
//

import Foundation

let allProviders: [RingProvider.Type] = [
    RestHRProvider.self,
    ActivityProvider.self,
    HRVProvider.self
]

protocol ProviderConfiguration: Codable {
    var provider: RingProvider.Type { get }
}




