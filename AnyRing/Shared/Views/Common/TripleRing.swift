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
    let color: Color
}

struct TripleRingView: View {
    let size: CGFloat
    let ring1: RingSnapshot
    let ring2: RingSnapshot
    let ring3: RingSnapshot
    private let margin: CGFloat = 1.0
    var body: some View {
        ZStack {
            let lineWidth = size / 9
            RingView(size: size, color: Color.green, progress: ring1.progress, lineWidth: lineWidth)
            RingView(size: size - 2 * (lineWidth + margin), color: Color.yellow, progress: ring2.progress, lineWidth: lineWidth)
            RingView(size: size - 4 * (lineWidth + margin), color: Color.blue, progress: ring3.progress, lineWidth: lineWidth)
        }
    }
}

