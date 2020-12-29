//
//  TripleRing.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import SwiftUI

struct RingSnapshot {
    let progress: Double
    let mainColor: Color
    var gradient: Bool = false
    var secondaryColor: Color? = nil
    var outerGlow: Bool = true
    var innerGlow: Bool = false
}

struct TripleRingView: View {
    let size: CGFloat
    let ring1: RingSnapshot
    let ring2: RingSnapshot
    let ring3: RingSnapshot
    var simplified: Bool = false
    private let margin: CGFloat = 1.5
    var body: some View {
        ZStack {
            let lineWidth = size / 9
            RingView(
                size: size,
                snapshot: ring1,
                lineWidth: lineWidth,
                simplified: simplified)
            RingView(
                size: size - 2 * (lineWidth + margin),
                snapshot: ring2,
                lineWidth: lineWidth,
                simplified: simplified)
            RingView(
                size: size - 4 * (lineWidth + margin),
                snapshot: ring3,
                lineWidth: lineWidth,
                simplified: simplified)
        }
    }
}

