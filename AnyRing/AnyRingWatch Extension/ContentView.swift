//
//  ContentView.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI
import WatchConnectivity
import ClockKit

struct WatchDashboard: View {
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    var size: CGFloat
    var days: Int
    var body: some View {
        ScrollView {
            TripleRingView(size: size,
                           ring1: ring1.snapshot(),
                           ring2: ring2.snapshot(),
                           ring3: ring3.snapshot(),
                           shape: RingShape.rectangular).padding(10)
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
                
                Text("\(days)-day period")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }.padding(.horizontal, 20)
        }
    }
}
struct ContentView: View {
    @ObservedObject var viewModel = AnyRingViewModel()
    let session = WCSessionSender()
    
    var body: some View {
        if (viewModel.dataSource.isAvailable() && !viewModel.showingAlert) {
            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height) - 10
                if let rings = viewModel.rings {
                    WatchDashboard(ring1: rings.first,
                                   ring2: rings.second,
                                   ring3: rings.third,
                                   size: size,
                                   days: viewModel.globalConfig.days)
                    .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
                        session.requestLatestConfig()
                        refreshComplication()
                    }.onAppear {
                        session.onConfigUpdated = {
                            if $0 != viewModel.config {
                                viewModel.updateConfigInABatch(config: $0)
                                viewModel.updateProviders()
                                refreshComplication()
                            }
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

class WCSessionSender: NSObject, WCSessionDelegate {
    var onActivated: (() -> Void)?
    var onConfigUpdated: ((AnyRingConfig) -> Void)?
    let session = WCSession.default
    override init() {
        super.init()
        onActivated = { [weak self] in
            guard let self = self else { return }
            self.session.sendMessage(["refresh": [:]]) { [weak self] userInfo in
                if let json = userInfo["config"] as? Data,
                   let decoded = try? JSONDecoder().decode(AnyRingConfig.self, from: json) {
                    self?.onConfigUpdated?(decoded)
                }
            } errorHandler: { err in
                print(">> error", err)
            }
        }
        session.delegate = self
        session.activate()
        
    }
    func requestLatestConfig() {
        onActivated?()
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?)
    {
        if (activationState == .activated) {
            onActivated?()
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let json = applicationContext["config"] as? Data {
            if let decoded = try? JSONDecoder().decode(AnyRingConfig.self, from: json) {
                onConfigUpdated?(decoded)
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
    }
}
