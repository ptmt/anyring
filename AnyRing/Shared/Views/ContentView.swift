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
                        watchSession.refreshComplication()
                    })
                    .environmentObject(viewModel)
                    .navigationTitle(Text("AnyRing"))
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                        viewModel.rings?.forEach { $0.refresh() }
                        refreshWidget()
                        watchSession.refreshComplication()
                    }.onAppear {
                        refreshWidget()
                        watchSession.refreshComplication()
                    }
                } else {
                    ProgressView().alert(isPresented: $viewModel.showingAlert) {
                        Alert(title: Text("Error"), message: Text("Permission to HealthKit is denied"), dismissButton: .default(Text("OK")))
                    }.navigationTitle(Text("AnyRing"))
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
    override init() {
        super.init()
        
        if WCSession.isSupported() && wcSession.isWatchAppInstalled {
            wcSession.delegate = self
            wcSession.activate()
        }
        
    }
    func refreshComplication() {
        if (wcSession.activationState == .activated) {
            wcSession.transferCurrentComplicationUserInfo([:])
        }
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("activated", activationState, error)
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("activated")
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
