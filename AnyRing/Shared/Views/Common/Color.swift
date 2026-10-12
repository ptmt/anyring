import SwiftUI

extension Color {
    func lighter(by percentage: CGFloat = 30) -> Color? { adjust(by: abs(percentage)) }
    func darker(by percentage: CGFloat = 30) -> Color? { adjust(by: -abs(percentage)) }
    func adjust(by percentage: CGFloat = 30) -> Color? {
        let rgba = CodableColor(self)
        let offset = Double(percentage) / 100
        return Color(.sRGB, red: min(1, max(0, rgba.red + offset)),
                     green: min(1, max(0, rgba.green + offset)),
                     blue: min(1, max(0, rgba.blue + offset)), opacity: rgba.alpha)
    }
    var inverted: Color {
        let rgba = CodableColor(self)
        return Color(.sRGB, red: 1 - rgba.red, green: 1 - rgba.green, blue: 1 - rgba.blue, opacity: rgba.alpha)
    }
}
