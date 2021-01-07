//
//  ContentView.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI
import WatchConnectivity
import ClockKit

struct ContentView: View {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var delegate
    @ObservedObject var viewModel = AnyRingViewModel()
    let session = WCSessionSender()
    
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
                            
                            Text("Data for \(viewModel.globalConfig.days)-day period")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }.padding(.horizontal, 20)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: WKExtension.applicationWillEnterForegroundNotification)) { _ in
                       refresh()
                    }.onAppear {
                        session.onConfigUpdated = {
                            viewModel.updateConfigInABatch(config: $0)
                            refresh()
                        }
                        session.requestLatestConfig()
                        refresh()
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
    
    func refresh() {
        delegate.onReload = {
            // refresh view model
            viewModel.updateProviders()
        }
        viewModel.updateProviders()
        refreshComplication()
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
