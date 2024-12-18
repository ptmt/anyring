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
            
            TextField("value", value: $state, format: .number).onChange(of: state) {
                onChange(state)
            }
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .fixedSize()
            
//            Stepper("", value: $state, in: 0...50000) { s in
//                if (!s) { onChange(state) }
//            }.fixedSize()
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
        }.onChange(of: isOn) {
            onChange(isOn)
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
            ring.update(config: newConfig)
            permissionsTask = self.vm.handlePermissions(permissions: [healthKitParams.sampleType.hkSampleType])
                .replaceError(with: false)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    
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
                    
                    ConfigTextValue(label: config.healthKitParams.reversed ? "Goal" : "Start from", state: ring.configuration.minValue) { changed in
                        var newConfig = ring.configuration
                        newConfig.minValue = changed
                        ring.update(config: newConfig)
                    }
                    
                    ConfigTextValue(label: config.healthKitParams.reversed ? "Start from" : "Goal", state:  ring.configuration.maxValue) { changed in
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
