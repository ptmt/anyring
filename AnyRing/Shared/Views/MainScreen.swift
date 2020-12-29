//
//  MainScreen.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct MainScreen: View {
    var rings: RingWrapper<RingViewModel>
    @State var selection = 1
    
    var body: some View {
        Form {
            Section {
                RingDashboard(size: 150,
                              ring1: rings.first,
                              ring2: rings.second,
                              ring3: rings.third).padding()
            }
            
            TemplatesView { newConfig in
                rings.first.updateFromSnapshot(snapshot: newConfig.first)
                rings.second.updateFromSnapshot(snapshot: newConfig.second)
                rings.third.updateFromSnapshot(snapshot: newConfig.third)
            }
            
            Section {
                Picker(selection: $selection, label: Text(""), content: {
                    Text("Ring 1").tag(1)
                    Text("Ring 2").tag(2)
                    Text("Ring 3").tag(3)
                }).pickerStyle(SegmentedPickerStyle())
            }
            
            switch(selection) {
            case 2: RingConfigurationView(ring: rings.second)
            case 3: RingConfigurationView(ring: rings.third)
            default: RingConfigurationView(ring: rings.first)
            }
        }
    }
}



struct MainScreen_Preview: PreviewProvider {
    static var previews: some View {
        MainScreen(rings: RingWrapper([
                                        DemoProvider().viewModel(),
                                        DemoProvider().viewModel(),
                                        DemoProvider().viewModel()]
        ))
    }
}


