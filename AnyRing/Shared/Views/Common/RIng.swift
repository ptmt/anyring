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
    var primaryColor: Color
    var secondaryColor: Color? = nil
    var progress: Double
    var lineWidth: CGFloat
    var outerGlow: Bool = true
    var innerGlow: Bool = true
    var body: some View {
        let angle: Double = progress * 360
        let gradient = AngularGradient(gradient: Gradient(colors: [secondaryColor ?? primaryColor.opacity(0.5), primaryColor]), center: .center,
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
                    
                    let angleForFinalSegment: CGFloat =  CGFloat(progress.truncatingRemainder(dividingBy: 1)) * (CGFloat(Double.pi))
                    
                    let angleForOffsetInRadians: CGFloat = angleForFinalSegment + CGFloat(Double.pi / 2)
                    let relativeXOffset = cos(angleForOffsetInRadians)
                    let relativeYOffset = sin(angleForOffsetInRadians)
                    let xOffset = relativeXOffset * 5
                    let yOffset = relativeYOffset * 5
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
            RingView(size: 140, primaryColor: Color.green, secondaryColor: Color(#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)), progress: 1.5, lineWidth: 20.0)
            RingView(size: 140, primaryColor: Color.yellow, secondaryColor: Color.white, progress: 1.5, lineWidth: 20)
            RingView(size: 125, primaryColor: Color.pink, secondaryColor: Color.red, progress: 0.75, lineWidth: 20)
            RingView(size: 50, primaryColor: Color.yellow, progress: 0.5, lineWidth: 8)
                .preferredColorScheme(.dark)
        }.previewLayout(.fixed(width: 150, height: 150))
    }
}
