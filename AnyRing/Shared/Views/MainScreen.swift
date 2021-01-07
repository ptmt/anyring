//
//  MainScreen.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct MainScreen: View {
    var rings: RingWrapper<RingViewModel>
    @EnvironmentObject var vm: AnyRingViewModel
    @State var days: Int
    @State var selection = 1
    var onPeriodChange: ((Int) -> Void)?
    
    var body: some View {
        Form {
            
            Section {
                RingDashboard(size: 150,
                              ring1: rings.first,
                              ring2: rings.second,
                              ring3: rings.third,
                              days: days).padding()
                TemplatesView { newConfig in
                    rings.first.updateFromSnapshot(snapshot: newConfig.first)
                    rings.second.updateFromSnapshot(snapshot: newConfig.second)
                    rings.third.updateFromSnapshot(snapshot: newConfig.third)
                    onPeriodChange?(vm.globalConfig.days)
                }
            }
            
            Section {
                HStack {
                    Text("Days")
                    Picker(selection: $days, label: Text("Days"), content: {
                        Text("1").tag(1)
                        Text("2").tag(2)
                        Text("3").tag(3)
                        Text("5").tag(5)
                        Text("7").tag(7)
                    })
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: days, perform: { value in
                        onPeriodChange?(days)
                    })
                }
                Text("You can choose how often the rings get reset. By default Activity Rings in iOS start over every 24 hours")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section() {
                Picker(selection: $selection, label: Text(""), content: {
                    Text("Ring 1").tag(1)
                    Text("Ring 2").tag(2)
                    Text("Ring 3").tag(3)
                }).pickerStyle(SegmentedPickerStyle())
            }
            
            switch(selection) {
            case 2: RingConfigurationView(ring: rings.second).environmentObject(vm)
            case 3: RingConfigurationView(ring: rings.third).environmentObject(vm)
            default: RingConfigurationView(ring: rings.first).environmentObject(vm)
            }
        }
    }
}



struct MainScreen_Preview: PreviewProvider {
    static var previews: some View {
        MainScreen(rings: RingWrapper([
                                        DemoProvider().viewModel( globalConfig:  GlobalConfiguration.Default),
                                        DemoProvider().viewModel(globalConfig:  GlobalConfiguration.Default),
                                        DemoProvider().viewModel(globalConfig:  GlobalConfiguration.Default)]),  days: 3)
    }
}


