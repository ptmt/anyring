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
    
    var body: some View {
        HStack(alignment: .center, spacing: 5) {
            TripleRingView(size: size,
                           ring1: ring1.snapshot(),
                           ring2: ring2.snapshot(),
                           ring3: ring3.snapshot())
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
                      ring1: DemoProvider("HRV", initValue: 110, units: "ms", config: .init(minValue: 0, maxValue: 10, appearance: RingAppearance(mainColor: CodableColor(.orange)))).viewModel(globalConfig:  GlobalConfiguration.Default),
                      ring2: DemoProvider("Heart Rate", initValue: 60, units: "bpm", config: .init(minValue: 10, maxValue: 70, appearance: RingAppearance(mainColor: CodableColor(.pink)))).viewModel(globalConfig:  GlobalConfiguration.Default),
                      ring3: DemoProvider("Activity", initValue: 30, units: "min", config:  .init(minValue: 10, maxValue: 70, appearance: RingAppearance(mainColor: CodableColor(.purple)))).viewModel(globalConfig:  GlobalConfiguration.Default))
            .padding()
    }
    static var previews: some View {
        Group {
            preview.preferredColorScheme(.dark)
            preview.preferredColorScheme(.light)
        }.previewLayout(.fixed(width: 350, height: 200))
         
    }
}
