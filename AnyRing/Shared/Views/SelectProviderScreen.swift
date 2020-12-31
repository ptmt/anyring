//
//  SelectProviderScreen.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 31.12.2020.
//

import Foundation
import SwiftUI

struct FillAll: View {
    let color: Color
    
    var body: some View {
        GeometryReader { proxy in
            self.color.frame(width: proxy.size.width * 1.3).fixedSize()
        }
    }
}

struct SelectProviderScreen: View {
    var selected: String
    var onSelect: (HealthKitProvider.HealthKitConfiguration) -> Void
    @Environment(\.presentationMode) var presentation
    @State private var searchText: String = ""
    var search: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary).padding(.leading, 10)
            TextField("Search providers", text: $searchText)
                .padding(10)
        }
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
        
    }
    var body: some View {
        List {
            
            Section(header: search) {
                ForEach(healthKitProviders.filter { searchText.isEmpty || $0.name.lowercased().contains(searchText.lowercased()) }, id: \.self) { provider in
                    VStack(alignment: .leading, spacing: 7) {
                        
                        Text(provider.name).bold()
                        Text(provider.description).font(.callout).foregroundColor(.secondary)
                        Text("Range by default: \(Int(provider.minValue)) - \(Int(provider.maxValue)) \(provider.units.hkunit.unitString)").font(.callout)
                        if (provider.name == selected) {
                            Button("Selected") {
                                
                            }.disabled(true)
                        } else {
                            
                            Button("Select") {
                                
                            }
                            .foregroundColor(Color.accentColor)
                        }
                    }.padding(.vertical, 10).onTapGesture {
                        onSelect(provider)
                        self.presentation.wrappedValue.dismiss()
                    }
                }
            }
            .textCase(nil)
        }.listStyle(GroupedListStyle())
        .navigationTitle(Text("Data Sources"))
    }
}

struct SelectProviderScreen_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            SelectProviderScreen(selected: "HRV") { _ in  }
        }
    }
}
