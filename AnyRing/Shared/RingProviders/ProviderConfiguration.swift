//
//  ProviderConfiguration.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 24.12.2020.
//

import Foundation
import Combine

enum RingID: Int, Codable, Sendable {
    case first, second, third
}

/// Strict, shared links used by the phone widgets; unrelated URLs are ignored.
enum WidgetDestination: Equatable {
    case overview
    case ring(RingID)

    var url: URL {
        switch self {
        case .overview: URL(string: "anyprogress://rings")!
        case .ring(let id): URL(string: "anyprogress://ring/\(id.rawValue)")!
        }
    }

    init?(url: URL) {
        guard url.scheme == "anyprogress", url.query == nil, url.fragment == nil,
              url.user == nil, url.password == nil, url.port == nil else { return nil }
        if url.host == "rings", url.path.isEmpty { self = .overview; return }
        guard url.host == "ring", let id = RingID.allWidgetIDs.first(where: { url.path == "/\($0.rawValue)" }) else { return nil }
        self = .ring(id)
    }
}

extension RingID {
    static let allWidgetIDs: [RingID] = [.first, .second, .third]
}

protocol ProviderConfiguration: Codable, Sendable {
    @MainActor var provider: RingProvider.Type { get }
    var ring: RingID { get }
    var name: String { get set }
    
    var minValue: Double { get set }
    var maxValue: Double { get set }
    
    var appearance: RingAppearance { get set }
    
    var units: String { get }
}

