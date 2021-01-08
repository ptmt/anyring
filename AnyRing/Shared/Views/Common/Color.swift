//
//  Color.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 08.01.2021.
//

import Foundation
import SwiftUI

extension Color {

    func lighter(by percentage: CGFloat = 30.0) -> Color? {
        return self.adjust(by: abs(percentage) )
    }

    func darker(by percentage: CGFloat = 30.0) -> Color? {
        return self.adjust(by: -1 * abs(percentage) )
    }

    func adjust(by percentage: CGFloat = 30.0) -> Color? {
        var red: Double = 0, green: Double = 0, blue: Double = 0

        let uiColor = UIColor(self)
        if let components = uiColor.cgColor.components {
            red = Double(min(components[0] + percentage/100, 1.0))
            green = Double(min(components[1] + percentage/100, 1.0))
            blue = Double(min(components[2] + percentage/100, 1.0))
            return Color(.sRGB,
                           red: red,
                           green: green,
                           blue: blue,
                opacity: Double(1.0))
        } else {
            return nil
        }
    }
    
    func blend(with: UIColor) -> Color {
        let colors = [UIColor(self), with]
        let numberOfColors = CGFloat(colors.count)
        var (red, green, blue, alpha) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))

        let componentsSum = colors.reduce((red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat())) { temp, color in
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return (temp.red+red, temp.green + green, temp.blue + blue, temp.alpha+alpha)
        }
        return Color(UIColor(red: componentsSum.red / numberOfColors,
                           green: componentsSum.green / numberOfColors,
                           blue: componentsSum.blue / numberOfColors,
                           alpha: componentsSum.alpha / numberOfColors))
    }
    
    var inverted: Color {
            var a: CGFloat = 0.0, r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0
        return UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) ? Color(UIColor(red: 1.0-r, green: 1.0-g, blue: 1.0-b, alpha: a)) : .black
        }
}
