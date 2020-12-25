//
//  MultiRing.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct RingDashboard: View {
    let size: CGFloat
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            let progress = ring1.progress.normalized
            TripleRingView(size: size,
                           ring1: .init(progress: progress, color: ring1.configuration.mainColor.color),
                           ring2: .init(progress: ring2.progress.normalized, color: ring2.configuration.mainColor.color),
                           ring3: .init(progress: ring3.progress.normalized, color:
                                            ring3.configuration.mainColor.color))
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                RingLabel(name: ring1.name,
                          value: String(describing: ring1.progress),
                          units: ring1.units,
                          color: ring1.configuration.mainColor.color)
                RingLabel(name: ring2.name,
                          value: String(describing: ring2.progress),
                          units: ring2.units,
                          color: ring2.configuration.mainColor.color)
                RingLabel(name: ring3.name,
                          value: String(describing: ring3.progress),
                          units: ring3.units,
                          color: ring3.configuration.mainColor.color)
                
                Text("3-day period").font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}


struct MultiRingView_Preview: PreviewProvider {
    static var previews: some View {
        RingDashboard(size: 150,
                      ring1: DemoProvider("HRV", initValue: 110, units: "ms", config: .init(minValue: 0, maxValue: 10, mainColor: CodableColor(.orange))).viewModel(),
                      ring2: DemoProvider("Heart Rate", initValue: 60, units: "bpm", config: .init(minValue: 10, maxValue: 70, mainColor: CodableColor(.pink))).viewModel(),
                      ring3: DemoProvider("Activity", initValue: 30, units: "min", config:  .init(minValue: 10, maxValue: 70, mainColor: CodableColor(.purple))).viewModel())
            .padding()
            .previewLayout(.fixed(width: 350, height: 200))
            .preferredColorScheme(.dark)
    }
}
