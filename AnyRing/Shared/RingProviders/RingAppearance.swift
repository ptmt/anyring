//
//  RingAppearance.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 30.12.2020.
//

import Foundation

struct RingAppearance: Codable {
    var mainColor: CodableColor
    var gradient: Bool = false
    var secondaryColor: CodableColor? = nil
    var outerGlow: Bool = true
    var innerGlow: Bool = false
}
