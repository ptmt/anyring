//
//  ContentView.swift
//  Shared
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    #if targetEnvironment(simulator)
      // your simulator code
    let dataSource = MockHealthKitDataSource()
    #else
      // your real device code
    let dataSource = DeviceHealthKitDataSource()
    #endif
    
    @State var showingAlert = false
    @State var rings: RingViewModel?
    @State var initTask: AnyCancellable? = nil
    
    var body: some View {
        NavigationView {
            if (dataSource.isAvailable()) {
                if let rings = rings {
                    MainScreen(rings: rings)
                        .navigationTitle(Text("AnyRing"))
                } else {
                    ProgressView().onAppear {
                        initViewModels()
                    }.alert(isPresented: $showingAlert) {
                        Alert(title: Text("Error"), message: Text("Permission to HealthKit is denided"), dismissButton: .default(Text("OK")))
                    }.navigationTitle(Text("AnyRing"))
                }
                
            } else {
                Text("Apple HealthKit data appears to be not available")
                    .padding()
            }
        }
    }
    
    private func initViewModels() {
        // instanitiate all ring providers
        let providers = RestHRProvider(dataSource: dataSource)
        
        // collect all permissions for healthkit
        initTask = providers.requestNeededPermissions().sink { _ in } receiveValue: { success in
            print("requestNeededPermissions", success)
            if (!success) {
                showingAlert = true
            } else {
                // instanitiate all view models
                rings = providers.viewModel()
            }
        }
    }
}

struct RingConfiguration {
    let provider: RingProvider.Type
}
struct RingsConfiguration {
    let ring1: RingConfiguration
}

let defaultConfig = RingsConfiguration(ring1: RingConfiguration(provider: RestHRProvider.self))


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
