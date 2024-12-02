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
                              days: days,
                              shape: .rectangular).padding()
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
                    .onChange(of: days) {
                        onPeriodChange?(days)
                    }
                }
                Text("Specify how often the progress starts from the beginning. For example you can aggregate number of steps over 3 days")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Configuration")) {
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
                                        DemoProvider(
                                            initValue: 50,
                                            config: DemoProvider.Configuration(
                                                name: "FirstRing",
                                                ring: .first,
                                                minValue: 0,
                                                maxValue: 100,
                                                appearance: RingAppearance(
                                                    mainColor: CodableColor(.red)),
                                                units: "M"))
                                            .viewModel(globalConfig: GlobalConfiguration.Default),
                                        DemoProvider(initValue: 50,
                                                     config: DemoProvider.Configuration(
                                                         name: "SecondRing",
                                                         ring: .second,
                                                         minValue: 0,
                                                         maxValue: 100,
                                                         appearance: RingAppearance(
                                                             mainColor: CodableColor(.blue)),
                                                         units: "M")
                                        ).viewModel(globalConfig:  GlobalConfiguration.Default),
                                        DemoProvider().viewModel(globalConfig:  GlobalConfiguration.Default)]),  days: 3)
            .environmentObject(AnyRingViewModel())
    }
}


