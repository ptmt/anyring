//
//  Glow.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 26.12.2020.
//

import Foundation
import SwiftUI

struct OuterGlow: ViewModifier {
    let color: Color
    
    init(_ color: Color) {
        self.color = color
    }
    
    func body(content: Content) -> some View {
        return content.shadow(color: color.opacity(0.5), radius: 12)
            .shadow(color: color.opacity(0.2), radius: 12)
            .shadow(color: color.opacity(0.1), radius: 12)
    }
}

struct InnerGlow: ViewModifier {
    let color: Color
    let size: CGFloat
    init(_ color: Color, size: CGFloat) {
        self.color = color
        self.size = size
    }
    
    func body(content: Content) -> some View {
        let glowColor = Color.white
        return content.overlay(
            Circle()
                .stroke(Color.clear,
                        lineWidth: 2)
                .shadow(color: glowColor.opacity(0.5),
                        radius: 2, x: 0, y: 0)
                .shadow(color: glowColor.opacity(0.1),
                        radius: 2, x: 0, y: 0)
                .shadow(color: glowColor.opacity(0.1),
                        radius: 5, x: 0, y: 0)
                .frame(width: size, height: size, alignment: .center)
        )
    }
}

extension View {
    func outerGlow(color: Color) -> some View {
        return self
            .shadow(color: color.opacity(0.5), radius: 12)
            .shadow(color: color.opacity(0.2), radius: 12)
            .shadow(color: color.opacity(0.1), radius: 12)
    }
    func innerShadow<S: Shape>(using shape: S, angle: Angle = .degrees(0), color: Color = .black, width: CGFloat = 6, blur: CGFloat = 6) -> some View {
            let finalX = CGFloat(cos(angle.radians - .pi / 2))
            let finalY = CGFloat(sin(angle.radians - .pi / 2))
            return self.overlay(
                shape
                    .stroke(color, lineWidth: width)
                    .offset(x: finalX * width * 0.6, y: finalY * width * 0.6)
                    .blur(radius: blur)
                    .mask(shape)
            )
        }
}
