//
//  MainScreen.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct MainScreen: View {
    var rings: RingWrapper<RingViewModel>
    @State var slider = 40
    @State var isOn = false
    @State var bgColor = Color.red
    var body: some View {
        Form {
            Section {
                MultiRingView(size: 150,
                              ring1: rings.first,
                              ring2: rings.second,
                              ring3: rings.third).padding()
            }
            
            Section(header: Text("Ring 1 - \(rings.first.name)")) {
                ColorPicker("Main Color", selection: $bgColor)
            }
            
            Section(header: Text("Ring 2 - \(rings.second.name)")) {
                ColorPicker("Main Color", selection: $bgColor)
                
                HStack {
                    VStack {
                        Text("Min Value").font(.footnote)
                            HStack { TextField("Min", value: $slider, formatter: DoubleFormatter())
                                Stepper("", value: $slider, in: 0...1000) { _ in
                                    
                                }
                            }
                        }
                }
                
                HStack {
                    VStack {
                        Text("Max Value").font(.footnote)
                            HStack { TextField("Min", value: $slider, formatter: DoubleFormatter())
                                Stepper("", value: $slider, in: 0...1000) { _ in
                                    
                                }
                            }
                        }
                }
                
                Toggle("Reversed direction", isOn: $isOn)
            }
            
            Section(header: Text("Ring 3 - \(rings.third.name)")) {
                
                HStack {
                    Text("Threshold")
                    
                }
            }
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


struct MainScreen_Preview: PreviewProvider {
    static var previews: some View {
        MainScreen(rings: RingWrapper([
                                        DemoProvider().viewModel(),
                                        DemoProvider().viewModel(),
                                        DemoProvider().viewModel()]
        ))
    }
}


