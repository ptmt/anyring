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
            
            Picker(selection: $selection, label: Text(""), content: {
                Text("Ring 1").tag(1)
                Text("Ring 2").tag(2)
                Text("Ring 3").tag(3)
            }).pickerStyle(SegmentedPickerStyle())
            
            switch(selection) {
            case 2: RingConfigurationView(ring: rings.second, ringConfig: RingConfigViewModel())
            case 3: RingConfigurationView(ring: rings.third, ringConfig: RingConfigViewModel())
            default: RingConfigurationView(ring: rings.first, ringConfig: RingConfigViewModel())
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


