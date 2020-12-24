//
//  RingConfigurationView.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 23.12.2020.
//

import Foundation
import SwiftUI

class RingConfigViewModel: ObservableObject {
    @Published var mainColor: Color = Color.red
    @Published var reversedDirection = false
    @Published var minimumValue = 40
    @Published var maximumValue = 100
}

struct RingConfigurationView: View {
    @ObservedObject var ring: RingViewModel
    @ObservedObject var ringConfig: RingConfigViewModel
    @State var slider = 40
    @State var isOn = false
    @State var ringMainColor = Color.red
    var body: some View {
        Group {
            Section(header: Text("Provider")) {
                
                NavigationLink(destination: Text("Providers are hard-coded now")) {
                    VStack {
                        Text("Data source: \(ring.name)")
                    }
                }
                Text(ring.providerDescription).font(.footnote)
            }
            Section(header: Text("Ring")) {
                
                ColorPicker("Main Color", selection: $ringConfig.mainColor)
                
                HStack {
                    Text("Min").padding()
                    Spacer().background(Color.red)
                    TextField("Min", value: $ringConfig.minimumValue, formatter: DoubleFormatter()).textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Stepper("", value: $slider, in: 0...1000) { _ in
                        
                    }
                }
                
                HStack {
                    Text("Max").padding()
                    Spacer()
                    TextField("Max", value: $ringConfig.maximumValue, formatter: DoubleFormatter()).textFieldStyle(RoundedBorderTextFieldStyle())
                    Stepper("", value: $slider, in: 0...1000) { _ in
                        
                    }
                }
                Toggle("Reversed direction", isOn: $ringConfig.reversedDirection)
            }
        }
    }
}

struct RingConfigurationView_Preview: PreviewProvider {
    static var previews: some View {
        Form {
            RingConfigurationView(ring: DemoProvider().viewModel(),
                                  ringConfig: RingConfigViewModel())
        }
    }
}


public class DoubleFormatter: Formatter {
    
    override public func string(for obj: Any?) -> String? {
        var retVal: String?
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let dbl = obj as? Double {
            retVal = formatter.string(from: NSNumber(value: dbl))
        } else {
            retVal = nil
        }
        
        return retVal
    }
    
    override public func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        
        var retVal = true
        
        if let dbl = Double(string), let objok = obj {
            objok.pointee = dbl as AnyObject?
            retVal = true
        } else {
            retVal = false
        }
        
        return retVal
        
    }
}
