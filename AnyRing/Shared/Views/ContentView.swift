//
//  ContentView.swift
//  Shared
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI
import Combine
import WidgetKit

struct ContentView: View {
    
    @ObservedObject var viewModel = AnyRingViewModel()
    
    var body: some View {
        NavigationView {
            if (viewModel.dataSource.isAvailable()) {
                if let rings = viewModel.rings {
                    MainScreen(rings: rings)
                        .navigationTitle(Text("AnyRing"))
                        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                            viewModel.rings?.forEach { $0.refresh() }
                            refreshWidget()
                        }.onAppear {
                            refreshWidget()
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
        }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
