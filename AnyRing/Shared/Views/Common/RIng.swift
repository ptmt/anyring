//
//  RIng.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct RingShape: Shape {
    var angle: Double
    // We start from the top
    static let baseAngle: Double = -90
    // This draws a simple arc from the start angle to the end angle
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let radius = min(width, height) / 2
        let center = CGPoint(x: width / 2, y: height / 2)
        let endAngle = Angle(degrees: angle + RingShape.baseAngle)
        
        return Path { path in
            path.addArc(center: center, radius: radius, startAngle: Angle(degrees: RingShape.baseAngle), endAngle: endAngle, clockwise: false)
        }
    }
}

struct RingView: View {
    var size: CGFloat
    var snapshot: RingSnapshot
    var lineWidth: CGFloat
    
    var primaryColor: Color {
        snapshot.mainColor
    }
    var secondaryColor: Color? {
        snapshot.secondaryColor
    }
    var progress: Double {
        snapshot.progress
    }
    var outerGlow: Bool {
        snapshot.outerGlow
    }
    var innerGlow: Bool {
        snapshot.innerGlow
    }
    var body: some View {
        let angle: Double = progress * 360
        let gradientSecondaryColor = snapshot.gradient ? (secondaryColor ?? primaryColor.opacity(0.5)) : primaryColor
        let gradient = AngularGradient(gradient: Gradient(colors: [gradientSecondaryColor, primaryColor]), center: .center,
                                       startAngle: Angle(degrees: RingShape.baseAngle),
                                       endAngle: Angle(degrees: angle  + RingShape.baseAngle))
        GeometryReader { geometry in
            ZStack {
               
                Circle()
                    .stroke(style: StrokeStyle.init(lineWidth: lineWidth, lineCap: .round))
                    .opacity(0.2)
                    .foregroundColor(primaryColor)
                
                RingShape(angle: angle)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .fill(gradient)
                    .conditionalModifier(outerGlow, OuterGlow(primaryColor))
                    .conditionalModifier(innerGlow, InnerGlow(primaryColor, size: size))
                   
                if progress > 1 {
                    let offsetRadius = geometry.size.width / 2
                    
                    let angleForFinalSegment: CGFloat =  CGFloat(progress.truncatingRemainder(dividingBy: 1) * Double.pi * 2) - CGFloat(Double.pi / 2)
                    
                    let angleForOffsetInRadians: CGFloat = angleForFinalSegment + CGFloat(Double.pi / 2)
                    let relativeXOffset = cos(angleForOffsetInRadians)
                    let relativeYOffset = sin(angleForOffsetInRadians)
                    let xOffset = relativeXOffset * 3
                    let yOffset = relativeYOffset * 3
                    Circle()
                        .fill(primaryColor)
                        .frame(width: lineWidth,
                               height: lineWidth,
                               alignment: .center)
                        .offset(x: offsetRadius * cos(angleForFinalSegment),
                                y: offsetRadius * sin(angleForFinalSegment))
                        .shadow(color: Color.black.opacity(0.2),
                                radius: 3,
                                x: xOffset,
                                y: yOffset)
                }
            }
        }
        .padding(.all, lineWidth / 2)
        .frame(width: size, height: size)
    }

}

extension View {
    // If condition is met, apply modifier, otherwise, leave the view untouched
    public func conditionalModifier<T>(_ condition: Bool, _ modifier: T) -> some View where T: ViewModifier {
        Group {
            if condition {
                self.modifier(modifier)
            } else {
                self
            }
        }
    }
}

struct RingView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            RingView(size: 140, snapshot: RingSnapshot(progress: 1.25, mainColor: Color.green, gradient: true, secondaryColor: Color(#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)), outerGlow: false), lineWidth: 20.0)
            RingView(size: 140, snapshot: RingSnapshot(progress: 1.75, mainColor: Color.red, gradient: true, secondaryColor: Color(#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)), outerGlow: true, innerGlow: true), lineWidth: 20.0)
            RingView(size: 100, snapshot: RingSnapshot(progress: 0.75, mainColor: Color.pink, gradient: false, outerGlow: false, innerGlow: false), lineWidth: 20.0)
                .preferredColorScheme(.dark)
        }.previewLayout(.fixed(width: 150, height: 150))
    }
}
