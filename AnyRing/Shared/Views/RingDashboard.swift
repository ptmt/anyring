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
    var days: Int = 3
    var shape: RingShape = .circle
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            TripleRingView(size: size,
                           ring1: ring1.snapshot(),
                           ring2: ring2.snapshot(),
                           ring3: ring3.snapshot(),
                           shape: shape)
            Spacer()
            VStack(alignment: .leading, spacing: 10) {
                RingLabel(name: ring1.name,
                          value: String(describing: ring1.progress),
                          units: ring1.units,
                          color: ring1.configuration.appearance.mainColor.color)
                RingLabel(name: ring2.name,
                          value: String(describing: ring2.progress),
                          units: ring2.units,
                          color: ring2.configuration.appearance.mainColor.color)
                RingLabel(name: ring3.name,
                          value: String(describing: ring3.progress),
                          units: ring3.units,
                          color: ring3.configuration.appearance.mainColor.color)
                
                Text("\(days)-day period").font(.footnote).foregroundColor(.secondary)
            }
        }
    }
}



struct MultiRingView_Preview: PreviewProvider {
    static var preview: some View {
        RingDashboard(size: 150,
                      ring1: DemoProvider(initValue: 110, config: .init(name: "HRV", ring: .first, minValue: 0, maxValue: 10, appearance: RingAppearance(mainColor: CodableColor(.orange)), units: "ms")).viewModel(globalConfig:  GlobalConfiguration.Default),
                      ring2: DemoProvider(initValue: 60, config: .init(name: "Heart Rate", ring: .second, minValue: 10, maxValue: 70, appearance: RingAppearance(mainColor: CodableColor(.pink)), units: "bpm")).viewModel(globalConfig:  GlobalConfiguration.Default),
                      ring3: DemoProvider(initValue: 30, config:  .init(name: "Activity", ring: .third, minValue: 10, maxValue: 70, appearance: RingAppearance(mainColor: CodableColor(.purple)), units: "minutes")).viewModel(globalConfig:  GlobalConfiguration.Default),
                      shape: .rectangular
        )
            .padding()
    }
    static var previews: some View {
        Group {
            preview.preferredColorScheme(.dark)
            preview.preferredColorScheme(.light)
        }.previewLayout(.fixed(width: 350, height: 200))
         
    }
}
