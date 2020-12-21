//
//  MainScreen.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct MainScreen: View {
    @ObservedObject var rings: RingViewModel
    @State var slider = 0.5
    @State var isOn = 0.5
    @State var bgColor = Color.red
    var body: some View {
        Form {
            Section {
                MultiRingView(size: 150, ring1: rings).padding()
            }
            
            Section(header: Text("Ring 1")) {
                HStack {
                    Text("Setting 1")
                }
            }
            
            Section(header: Text("Ring 2")) {
                ColorPicker("Main Color", selection: $bgColor)
                
                HStack {
                    Text("Threshold")
                    
                    Slider(value: $slider)
                }
            }
            
            Section(header: Text("Ring 3")) {
                Text("Setting 1")
                
                Text("Setting 2")
                
                HStack {
                    Text("Threshold")
                    
                    Slider(value: $slider)
                }
            }
        }
    }
}


struct MainScreen_Preview: PreviewProvider {
    static var previews: some View {
        MainScreen(rings: DemoProvider().viewModel())
    }
}


