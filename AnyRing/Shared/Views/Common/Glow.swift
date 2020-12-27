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
    let lineWidth: CGFloat
    let halfCircle: Bool
    
    private func shape() -> some Shape {
        halfCircle ? AnyShape(HalfCircle()) : AnyShape(Circle())
    }
    
    init(_ color: Color, size: CGFloat, lineWidth: CGFloat, halfCircle: Bool = false) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.halfCircle = halfCircle
    }
    
    func body(content: Content) -> some View {
        let glowColor = Color.white
        return content.overlay(
            ZStack {
                shape()
                    .stroke(Color.clear,
                            lineWidth: 2)
                    .shadow(color: glowColor.opacity(0.2),
                            radius: 3, x: 0, y: 0)
                    .shadow(color: glowColor.opacity(0.1),
                            radius: 2, x: 0, y: 0)
                    .shadow(color: glowColor.opacity(0.1),
                            radius: 5, x: 0, y: 0)
                    .frame(width: size, height: size, alignment: .center)
                shape()
                        .stroke(Color.clear,
                                lineWidth: 2)
                        .shadow(color: glowColor.opacity(0.2),
                                radius: 3, x: 0, y: 0)
                        .shadow(color: glowColor.opacity(0.1),
                                radius: 2, x: 0, y: 0)
                        .shadow(color: glowColor.opacity(0.1),
                                radius: 5, x: 0, y: 0)
                        .frame(width: size - 2 * lineWidth, height: size - 2 * lineWidth, alignment: .center)
            }
        )
    }
}


// https://stackoverflow.com/questions/61503390/get-shape-for-view-dynamically-in-swiftui
struct AnyShape: Shape {
    init<S: Shape>(_ wrapped: S) {
        _path = { rect in
            let path = wrapped.path(in: rect)
            return path
        }
    }

    func path(in rect: CGRect) -> Path {
        return _path(rect)
    }

    private let _path: (CGRect) -> Path
}
