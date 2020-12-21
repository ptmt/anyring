//
//  MultiRing.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct RingLabel: View {
    let name: String
    let value: String
    let units: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.footnote)
            (
                Text(String(describing: value)).bold() +
                    Text(" " + units).font(.footnote)
            ).foregroundColor(color)
        }
    }
}

struct MultiRingView: View {
    let size: CGFloat
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    private let margin: CGFloat = 1.0
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                let lineWidth = size / 9
                RingView(size: size, color: Color.green, progress: ring1.progress.normalized, lineWidth: lineWidth)
                RingView(size: size - 2 * (lineWidth + margin), color: Color.yellow, progress: ring2.progress.normalized, lineWidth: lineWidth)
                RingView(size: size - 4 * (lineWidth + margin), color: Color.blue, progress: ring3.progress.normalized, lineWidth: lineWidth)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                RingLabel(name: ring1.name,
                          value: String(describing: ring1.progress),
                          units: ring1.units,
                          color: Color.green)
                RingLabel(name: ring2.name,
                          value: String(describing: ring2.progress),
                          units: ring2.units,
                          color: Color.yellow)
                RingLabel(name: ring3.name,
                          value: String(describing: ring3.progress),
                          units: ring3.units,
                          color: Color.blue)
                
                Text("3-day period").font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}


struct MultiRingView_Preview: PreviewProvider {
    static var previews: some View {
        MultiRingView(size: 150,
                      ring1: DemoProvider("HRV", initValue: 120, units: "ms").viewModel(),
                      ring2: DemoProvider("Heart Rate", initValue: 60, units: "bpm").viewModel(),
                      ring3: DemoProvider("Activity", initValue: 30, units: "min").viewModel())
            .padding()
            .previewLayout(.fixed(width: 350, height: 200))
            .preferredColorScheme(.dark)
    }
}
