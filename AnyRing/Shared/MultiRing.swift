//
//  MultiRing.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct MultiRingView: View {
    let size: CGFloat
    @ObservedObject var ring1: RingViewModel
    private let margin: CGFloat = 1.0
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                let lineWidth = size / 9
                RingView(size: size, color: Color.green, progress: ring1.progress.normalized, lineWidth: lineWidth)
                RingView(size: size - 2 * (lineWidth + margin), color: Color.yellow, progress: 0, lineWidth: lineWidth)
                RingView(size: size - 4 * (lineWidth + margin), color: Color.blue, progress: 0, lineWidth: lineWidth)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading) {
                    Text("\(ring1.name)").font(.footnote)
                    (
                        Text(String(describing: ring1.progress)).bold() +
                            Text(String(describing: ring1.units)).font(.footnote)
                    ).foregroundColor(Color.green)
                }
                
                VStack(alignment: .leading) {
                    Text("\(ring1.name)").font(.footnote)
                    (
                        Text(String(describing: ring1.progress)).bold() +
                            Text(String(describing: ring1.units)).font(.footnote)
                    ).foregroundColor(Color.yellow)
                }
                
                VStack(alignment: .leading) {
                    Text("\(ring1.name)").font(.footnote)
                    (
                        Text(String(describing: ring1.progress)).bold() +
                            Text(String(describing: ring1.units)).font(.footnote)
                    ).foregroundColor(Color.blue)
                }
            }
        }
    }
}


struct MultiRingView_Preview: PreviewProvider {
    static var previews: some View {
        MultiRingView(size: 140, ring1: DemoProvider().viewModel())
            .previewLayout(.fixed(width: 350, height: 150))
            .preferredColorScheme(.dark)
    }
}
