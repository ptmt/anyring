//
//  ContentView.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI
import ClockKit

struct ContentView: View {
    
    @ObservedObject var viewModel = AnyRingViewModel()
    
    var body: some View {
        if (viewModel.dataSource.isAvailable() && !viewModel.showingAlert) {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) - 10
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
                                      color: rings.first.configuration.appearance.mainColor.color)
                            RingLabel(name: rings.second.name,
                                      value: String(describing: rings.second.progress),
                                      units: rings.second.units,
                                      color: rings.second.configuration.appearance.mainColor.color)
                            RingLabel(name: rings.third.name,
                                      value: String(describing: rings.third.progress),
                                      units: rings.third.units,
                                      color: rings.third.configuration.appearance.mainColor.color)
                            
                            Text("\(viewModel.globalConfig.days)-day period")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }.padding(.horizontal, 20)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
                        viewModel.updateProviders()
                        refreshComplication()
                    }.onAppear {
                        viewModel.updateProviders()
                        refreshComplication()
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

func refreshComplication() {
    let server = CLKComplicationServer.sharedInstance()
    server.activeComplications?.forEach {
        server.reloadTimeline(for: $0)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
