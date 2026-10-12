import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Portable colors, with a decoder for UIColor archives saved by previous releases.
struct CodableColor: Codable, Sendable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    var color: Color { Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha) }

    init(_ color: Color) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Self.component(Double(r)); green = Self.component(Double(g))
        blue = Self.component(Double(b)); alpha = Self.component(Double(a))
        #else
        let converted = NSColor(color).usingColorSpace(.sRGB) ?? .black
        red = Self.component(converted.redComponent); green = Self.component(converted.greenComponent)
        blue = Self.component(converted.blueComponent); alpha = Self.component(converted.alphaComponent)
        #endif
    }

    // Normalize float noise introduced by UIKit color archive round trips.
    private static func component(_ value: Double) -> Double { (value * 1_000_000).rounded() / 1_000_000 }

    private init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = Self.component(red); self.green = Self.component(green)
        self.blue = Self.component(blue); self.alpha = Self.component(alpha)
    }

    func encode(to encoder: Encoder) throws {
        #if canImport(UIKit)
        if encoder.userInfo[.legacyColorArchive] as? Bool == true {
            var container = encoder.singleValueContainer()
            let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(color), requiringSecureCoding: false)
            try container.encode(data)
            return
        }
        #endif
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(red, forKey: .red)
        try container.encode(green, forKey: .green)
        try container.encode(blue, forKey: .blue)
        try container.encode(alpha, forKey: .alpha)
    }

    enum CodingKeys: String, CodingKey { case red, green, blue, alpha }

    init(from decoder: Decoder) throws {
        if let values = try? decoder.container(keyedBy: CodingKeys.self) {
            self.init(red: try values.decode(Double.self, forKey: .red),
                      green: try values.decode(Double.self, forKey: .green),
                      blue: try values.decode(Double.self, forKey: .blue),
                      alpha: try values.decode(Double.self, forKey: .alpha))
            guard [red, green, blue, alpha].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid color components"))
            }
        } else {
            let container = try decoder.singleValueContainer()
            let data = try container.decode(Data.self)
            #if canImport(UIKit)
            guard let legacy = try NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: data) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid legacy color")
            }
            self.init(Color(legacy))
            #else
            guard let legacy = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid legacy color")
            }
            self.init(Color(legacy))
            #endif
        }
    }
}

extension CodingUserInfoKey {
    static let legacyColorArchive = CodingUserInfoKey(rawValue: "legacyColorArchive")!
}
