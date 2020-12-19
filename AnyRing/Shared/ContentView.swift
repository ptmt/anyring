//
//  ContentView.swift
//  Shared
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI

struct ContentView: View {
    let dataSource = HealthKitDataSource()
    
    var body: some View {
        NavigationView {
            if (dataSource.isAvailable()) {
                MainScreen().onAppear {
                    dataSource.requestAllPermissions()
                    dataSource.getTodaysHeartRates()
                }.navigationTitle(Text("AnyRing"))
            } else {
                Text("Apple HealthKit data appears to be not available")
                    .padding()
            }
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
