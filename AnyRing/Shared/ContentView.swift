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
    
    @State var rings: RingViewModel?
    var body: some View {
        NavigationView {
            if (dataSource.isAvailable()) {
                if let rings = rings {
                    MainScreen(rings: rings)
                        .navigationTitle(Text("AnyRing"))
                } else {
                    ProgressView().onAppear {
                        initViewModels()
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
        
        // collect all permissions for healthkit
        
        // instanitiate all view models
        rings = RestHRProvider(dataSource: dataSource).viewModel()
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
