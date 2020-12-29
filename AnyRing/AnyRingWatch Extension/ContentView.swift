//
//  ContentView.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject var viewModel = AnyRingViewModel()
    
    var body: some View {
        if (viewModel.dataSource.isAvailable()) {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) - 20
                if let rings = viewModel.rings {
                    ScrollView {
                        TripleRingView(size: size,
                                       ring1: rings.first.snapshot(),
                                       ring2: rings.second.snapshot(),
                                       ring3: rings.third.snapshot()).padding(10)
                        VStack(alignment: .leading, spacing: 10) {
                            RingLabel(name: rings.first.name,
                                      value: String(describing: rings.first.progress),
                                      units: rings.first.units,
                                      color: rings.first.configuration.mainColor.color)
                            RingLabel(name: rings.second.name,
                                      value: String(describing: rings.second.progress),
                                      units: rings.second.units,
                                      color: rings.second.configuration.mainColor.color)
                            RingLabel(name: rings.third.name,
                                      value: String(describing: rings.third.progress),
                                      units: rings.third.units,
                                      color: rings.third.configuration.mainColor.color)
                            
                            Text("3-day period").font(.footnote).foregroundColor(.secondary)
                        }
                    }
                    
                } else {
                    ProgressView()
                }
            }
            
        } else {
            Text("Apple HealthKit data appears to be not available")
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
