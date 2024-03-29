//
//  ContentView.swift
//  Shared
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI
import Combine
import WidgetKit
import WatchConnectivity
import UIKit

struct ContentView: View {
    
    @ObservedObject var viewModel = AnyRingViewModel()
    let watchSession = WatchSession()
    
    var body: some View {
        NavigationView {
            if (viewModel.dataSource.isAvailable()) {
                if let rings = viewModel.rings {
                    MainScreen(rings: rings, days: viewModel.globalConfig.days, onPeriodChange: { period in
                        viewModel.updatePeriod(days: period)
                        refreshWidget()
                        watchSession.sendConfigToWatch(config: viewModel.config)
                    })
                    .environmentObject(viewModel)
                    .navigationTitle(Text("AnyProgress"))
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        viewModel.rings?.forEach { $0.refresh() }
                        refreshWidget()
                        watchSession.sendConfigToWatch(config: viewModel.config)
                    }.onAppear {
                        refreshWidget()
                        watchSession.sendConfigToWatch(config: viewModel.config)
                        watchSession.onConfig = {
                            self.viewModel.config
                        }
                    }
                } else {
                    if (viewModel.showingAlert) {
                        VStack(spacing: 8) {
                            Text("Permission to HealthKit is denied").bold()
                            Button("Open HealthKit") {
                                UIApplication.shared.open(URL(string: "x-apple-health://")!, options: [:], completionHandler: nil)
                            }
                            Text("Check Sharing -> Apps")
                        }.navigationTitle(Text("AnyProgress"))
                    } else {
                        ProgressView().navigationTitle(Text("AnyProgress"))
                    }
                }
                
            } else {
                Text("Apple HealthKit data appears to be not available")
                    .padding()
            }
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
}

func refreshWidget() {
    WidgetCenter.shared.getCurrentConfigurations { result in
        guard case .success(_) = result else { return }
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}


class WatchSession: NSObject, WCSessionDelegate {
    let wcSession = WCSession.default
    var onConfig: (() -> AnyRingConfig)?
    override init() {
        super.init()
        if WCSession.isSupported() {
            wcSession.delegate = self
            wcSession.activate()
        }
        
    }
    func sendConfigToWatch(config: AnyRingConfig) {
        if (wcSession.activationState == .activated && wcSession.isWatchAppInstalled) {
            do {
                let encoded = try JSONEncoder().encode(config)
                try wcSession.updateApplicationContext(["config": encoded])
            } catch {
                print(error)
            }
            wcSession.transferCurrentComplicationUserInfo([:])
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let onConfig = onConfig {
            do {
                let encoded = try JSONEncoder().encode(onConfig())
                replyHandler(["config": encoded])
            } catch {
                print(error)
                replyHandler([:])
            }
        } else {
            replyHandler([:])
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
