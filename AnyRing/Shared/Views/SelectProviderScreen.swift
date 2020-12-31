//
//  SelectProviderScreen.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 31.12.2020.
//

import Foundation
import SwiftUI

struct SelectProviderScreen: View {
    var selected: String
    var body: some View {
        Form {
            ForEach(healthKitProviders, id: \.self) { provider in
                Section {
                    Text(provider.name)
                    Text(provider.description).font(.callout).foregroundColor(.secondary)
                    Text("\(Int(provider.minValue)) - \(Int(provider.maxValue)) \(provider.units.hkunit.unitString)")
                    if (provider.name == selected) {
                        Button("Selected") {
                            
                        }.disabled(true)
                    } else {
                        Button("Select") {
                            
                        }
                    }
                }
            }
        }.navigationTitle(Text("Data Sources"))
    }
}

struct SelectProviderScreen_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            SelectProviderScreen(selected: "HRV")
        }
    }
}
