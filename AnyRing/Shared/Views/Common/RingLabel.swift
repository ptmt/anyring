//
//  RingLabel.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import SwiftUI

struct RingLabel: View {
    let name: String
    let value: String
    let units: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.footnote)
            (
                Text(String(describing: value)).bold() +
                    Text(" " + units).font(.footnote)
            ).foregroundColor(color)
        }
    }
}
