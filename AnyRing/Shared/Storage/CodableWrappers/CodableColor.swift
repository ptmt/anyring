//
//  CodableColor.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 31.12.2020.
//

import Foundation
import SwiftUI

struct CodableColor: Codable {
    let color: Color
    init(_ color: Color) {
        self.color = color
    }

    enum CodingKeys: String, CodingKey {
        case color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        if let uiColor = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) {
            self.color = Color(uiColor)
        } else {
            self.color = Color.red // fail silently
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let uiColor = UIColor(color)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try container.encode(colorData)
    }
}
