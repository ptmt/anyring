//
//  MultiRing.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct MultiRingView: View {
    let size: CGFloat
    let ring1: RingViewModel
    private let margin: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            let lineWidth = size / 8
            RingView(size: size, color: Color.green, progress: 0.5, lineWidth: lineWidth)
            RingView(size: size - 2 * (lineWidth + margin), color: Color.yellow, progress: 0.5, lineWidth: lineWidth)
            RingView(size: size - 4 * (lineWidth + margin), color: Color.blue, progress: 1.1, lineWidth: lineWidth)
        }
    }
}


struct MultiRingView_Preview: PreviewProvider {
    static var previews: some View {
        MultiRingView(size: 140, ring1: DemoProvider().viewModel())
            .previewLayout(.fixed(width: 150, height: 150))
            .preferredColorScheme(.dark)
    }
}
