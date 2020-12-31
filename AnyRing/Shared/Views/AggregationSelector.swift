//
//  AggregationSelector.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 31.12.2020.
//

import Foundation
import SwiftUI

struct ConfigAggregation: View {
    @State var tag: Aggregation
    var onChange: (Aggregation) -> Void
    
    var body: some View {
        HStack {
            Text("Aggregate")
            Picker(selection: $tag, label: Text("Aggregation"), content: {
                Text("Avg").tag(Aggregation.avg)
                Text("Sum").tag(Aggregation.sum)
                Text("Min").tag(Aggregation.min)
                Text("Max").tag(Aggregation.max)
            })
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: tag) { value in
              onChange(value)
            }
        }
    }
}


struct ConfigAggregation_Preview: PreviewProvider {
    static var previews: some View {
        Form {
            ConfigAggregation(tag: .sum) { _ in
                
            }
        }
    }
}
