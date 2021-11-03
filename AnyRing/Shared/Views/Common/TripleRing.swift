//
//  TripleRing.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import SwiftUI

enum RingShape: String, Codable {
    case circle, rectangular
}

struct RingSnapshot: Codable {
    let progress: Double
    let mainColor: CodableColor
    var gradient: Bool = false
    var secondaryColor: CodableColor? = nil
    var outerGlow: Bool = true
    var innerGlow: Bool = false
}

struct TripleRingView: View {
    let size: CGFloat
    let ring1: RingSnapshot
    let ring2: RingSnapshot
    let ring3: RingSnapshot
    var simplified: Bool = false
    var shape: RingShape = .rectangular
    private let margin: CGFloat = 1.5
    var body: some View {
        ZStack {
            switch (shape) {
            case .circle:
                let lineWidth = size / 9
                let margin: CGFloat = 1.5
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
            case .rectangular:
                let lineWidth = size / 9
                let margin: CGFloat = 1.5
                RectangularView(
                    size: size,
                    snapshot: ring1,
                    lineWidth: lineWidth,
                    simplified: simplified)
                RectangularView(
                    size: size - 2 * (lineWidth + margin),
                    snapshot: ring2,
                    lineWidth: lineWidth,
                    simplified: simplified)
                RectangularView(
                    size: size - 4 * (lineWidth + margin),
                    snapshot: ring3,
                    lineWidth: lineWidth,
                    simplified: simplified)
            }
            
        }
    }
}



struct RipleRingView_Preview: PreviewProvider {
    static var previews: some View {
        
            TripleRingView(size: 500,
                           ring1: TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xffe6e6)),
                           ring2: TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xffabe1)),
                           ring3: TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xa685e2)),
                           shape: .rectangular
            )
       
            .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 1024, height: 1024))
//            .background(Color.black)
    }
}
