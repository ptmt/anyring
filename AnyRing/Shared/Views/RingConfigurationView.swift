//
//  RingConfigurationView.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 23.12.2020.
//

import Foundation
import SwiftUI
import Combine


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
            
            Stepper("", value: $state, in: 0...50000) { s in
                if (!s) { onChange(state) }
            }.fixedSize()
        }
    }
}

struct ConfigBoolValue: View {
    var label: String
    @State var isOn: Bool
    var onChange: (Bool) -> Void
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(label)
        }.onChange(of: isOn) { value in
            onChange(value)
        }
    }
}


struct RingConfigurationView: View {
    @ObservedObject var ring: RingViewModel
    @EnvironmentObject var vm: AnyRingViewModel
    @State private var permissionsTask: Cancellable? = nil
    
    var providerSelection: some View {
        SelectProviderScreen(selected: ring.configuration.name) { healthKitParams in
            var newConfig = ring.configuration as! HealthKitProvider.Configuration
            newConfig.healthKitParams = healthKitParams
            print("new config", healthKitParams.maxValue)
            ring.update(config: newConfig)
            permissionsTask = self.vm.handlePermissions(permissions: [healthKitParams.sampleType.hkSampleType])
                .replaceError(with: false)
                .receive(on: DispatchQueue.main)
                .sink { res in
                    
                }
        }
    }
    var body: some View {
        let ringMainColor = Binding<Color>(get: {
            ring.configuration.appearance.mainColor.color
        }, set: {
            var newConfig = ring.configuration
            newConfig.appearance.mainColor = CodableColor($0)
            ring.update(config: newConfig)
        })
        let secondaryColor = Binding<Color>(get: {
            ring.configuration.appearance.secondaryColor?.color ?? ring.configuration.appearance.mainColor.color.opacity(0.5)
        }, set: {
            var newConfig = ring.configuration
            newConfig.appearance.secondaryColor = CodableColor($0)
            ring.update(config: newConfig)
        })
        Group {
            Section(header: Text("Data Source")) {
                NavigationLink(destination: providerSelection) {
                    Text(ring.fullName)
                }
                Text(ring.providerDescription)
                    .font(.footnote)
                    .foregroundColor(Color.secondary)
                
                if let config = ring.configuration as? HealthKitProvider.Configuration {
                    
                    ConfigTextValue(label: config.healthKitParams.reversed ? "Goal" : "Empty Ring", state: ring.configuration.minValue) { changed in
                        var newConfig = ring.configuration
                        newConfig.minValue = changed
                        ring.update(config: newConfig)
                    }
                    ConfigTextValue(label: config.healthKitParams.reversed ? "Empty Ring" : "Goal", state:  ring.configuration.maxValue) { changed in
                        var newConfig = ring.configuration
                        newConfig.maxValue = changed
                        ring.update(config: newConfig)
                    }
                    
                    ConfigBoolValue(label: "Reversed direction", isOn: config.healthKitParams.reversed) { changed in
                        var newConfig = config
                        newConfig.healthKitParams.reversed = changed
                        ring.update(config: newConfig)
                    }
                    
                    
                    ConfigAggregation(tag: config.healthKitParams.aggregation) { changed in
                        var newConfig = config
                        newConfig.healthKitParams.aggregation = changed
                        ring.update(config: newConfig)
                    }
                }
            }
            
            Section(header: Text("Appearance")) {
                ColorPicker("Main Color", selection: ringMainColor)
                
                ConfigBoolValue(label: "Gradient", isOn: ring.configuration.appearance.gradient) { changed in
                    var newConfig = ring.configuration
                    newConfig.appearance.gradient = changed
                    ring.update(config: newConfig)
                }
                
                if (ring.configuration.appearance.gradient) {
                    ColorPicker("Second Gradient Color", selection: secondaryColor)
                }
                
                ConfigBoolValue(label: "Inner Glow", isOn: ring.configuration.appearance.innerGlow) { changed in
                    var newConfig = ring.configuration
                    newConfig.appearance.innerGlow = changed
                    ring.update(config: newConfig)
                }
                
                ConfigBoolValue(label: "Outer Glow", isOn: ring.configuration.appearance.outerGlow) { changed in
                    var newConfig = ring.configuration
                    newConfig.appearance.outerGlow = changed
                    ring.update(config: newConfig)
                }
            }
        }
    }
}

struct RingConfigurationView_Preview: PreviewProvider {
    static var previews: some View {
        Form {
            RingConfigurationView(ring: DemoProvider().viewModel(globalConfig:  GlobalConfiguration.Default))
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
