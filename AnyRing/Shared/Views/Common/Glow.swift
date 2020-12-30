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
    let simplified: Bool
    
    init(_ color: Color, simplified: Bool = false) {
        self.color = color
        self.simplified = simplified
    }
    
    func body(content: Content) -> some View {
        if (simplified) {
            return AnyView(content.shadow(color: color.opacity(0.5), radius: 4))
        } else {
            return AnyView(content.shadow(color: color.opacity(0.5), radius: 12)
                            .shadow(color: color.opacity(0.2), radius: 12)
                            .shadow(color: color.opacity(0.1), radius: 12))
        }
    }
}

struct InnerGlow: ViewModifier {
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat
    let halfCircle: Bool
    let progress: CGFloat
    
    private func shape() -> some Shape {
        halfCircle ? AnyShape(HalfCircle()) : AnyShape(Circle())
    }
    
    init(_ color: Color, size: CGFloat, lineWidth: CGFloat, progress: Double, halfCircle: Bool = false) {
        self.color = color
        self.size = size
        self.lineWidth = lineWidth
        self.halfCircle = halfCircle
        self.progress = CGFloat(progress)
    }
    
    func body(content: Content) -> some View {
        let glowColor = Color.white
        return content.overlay(
            ZStack {
                shape()
                    .trim(from: 0, to: progress)
                    .stroke(Color.clear,
                            lineWidth: lineWidth / 7)
                    .shadow(color: glowColor.opacity(0.2),
                            radius: 3, x: 0, y: 0)
                    .shadow(color: glowColor.opacity(0.1),
                            radius: 2, x: 0, y: 0)
                    .shadow(color: glowColor.opacity(0.1),
                            radius: 5, x: 0, y: 0)
                    .frame(width: size, height: size, alignment: .center)
                if (!halfCircle) {
                    shape()
                        .trim(from: 0, to: progress)
                        .stroke(Color.clear,
                                lineWidth: lineWidth / 7)
                        .shadow(color: glowColor.opacity(0.2),
                                radius: 3, x: 0, y: 0)
                        .shadow(color: glowColor.opacity(0.1),
                                radius: 2, x: 0, y: 0)
                        .shadow(color: glowColor.opacity(0.1),
                                radius: 5, x: 0, y: 0)
                        .frame(width: size - 2 * lineWidth, height: size - 2 * lineWidth, alignment: .center)
                }
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
