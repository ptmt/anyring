//
//  RingConfigurationView.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 23.12.2020.
//

import Foundation
import SwiftUI
import Combine

class RingConfigViewModel: ObservableObject {
    //    private let provider: RingProvider
    //    init(provider: RingProvider) {
    //        self.provider = provider
    //    }
    @Published var mainColor: Color = Color.red
    @Published var minimumValue = 40
    @Published var maximumValue = 100
    private var cancellables = Set<AnyCancellable>()
    init() {
        $mainColor.sink {
            print(">> main color changed", $0)
        }.store(in: &cancellables)
    }
}

struct ConfigTextValue: View {
    var label: String
    @State var state: Double
    var onChange: (Double) -> Void
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            
            TextField("Min", value: $state, formatter: DoubleFormatter(), onEditingChanged: { s in
                if (!s) { onChange(state) }
            }).textFieldStyle(RoundedBorderTextFieldStyle())
                .fixedSize()
            
            Stepper("", value: $state, in: 0...1000) { s in
                if (!s) { onChange(state) }
            }.fixedSize()
        }
    }
}
struct RingConfigurationView: View {
    @ObservedObject var ring: RingViewModel
    
    
    var body: some View {
        let ringMainColor = Binding<Color>(get: {
            ring.configuration.mainColor.color
        }, set: {
            var newConfig = ring.configuration
            newConfig.mainColor = CodableColor($0)
            ring.update(config: newConfig)
        })
        Group {
            Section(header: Text("Data Source")) {
                NavigationLink(destination: Text("Providers are hard-coded now")) {
                    Text(ring.name)
                }
                Text(ring.providerDescription)
                    .font(.footnote)
                    .foregroundColor(Color.secondary)
                
                
                ConfigTextValue(label: "Min value", state: ring.configuration.minValue) { changed in
                    print(">>>", changed)
                    var newConfig = ring.configuration
                    newConfig.minValue = changed
                    ring.update(config: newConfig)
                }
                ConfigTextValue(label: "Max value", state:  ring.configuration.maxValue) { changed in
                    var newConfig = ring.configuration
                    newConfig.maxValue = changed
                    ring.update(config: newConfig)
                }
            }
            
            Section(header: Text("Appearance")) {
                ColorPicker("Main Color", selection: ringMainColor)
            }
        }
    }
}

struct RingConfigurationView_Preview: PreviewProvider {
    static var previews: some View {
        Form {
            RingConfigurationView(ring: DemoProvider().viewModel())
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
