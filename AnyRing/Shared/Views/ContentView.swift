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
    @State var rings: RingWrapper<RingViewModel>?
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
        let providers: [RingProvider] = [
            RestHRProvider(dataSource: dataSource),
            HRVProvider(dataSource: dataSource),
            ActivityProvider(dataSource: dataSource),
        ]
        
        // collect all permissions for healthkit
        let permissions = providers.compactMap { $0.requiredHKPermission }
        
        initTask = dataSource.requestPermissions(permissions: Set(permissions)).sink { _ in } receiveValue: { success in
            if (!success) {
                showingAlert = true
            } else {
                // instanitiate all view models
                rings = RingWrapper(providers.map { $0.viewModel() })
            }
        }
    }
}

struct RingWrapper<T> {
    private let list: [T]
    init(_ list: [T]) {
        precondition(list.count == 3)
        self.list = list
    }
    var first: T {
        list.first!
    }
    var second: T {
        list[1]
    }
    var third: T {
        list[2]
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
