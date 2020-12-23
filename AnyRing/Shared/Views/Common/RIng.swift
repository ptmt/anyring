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
    let baseAngle: Double = -90
    // This draws a simple arc from the start angle to the end angle
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let radius = min(width, height) / 2
        let center = CGPoint(x: width / 2, y: height / 2)
        let endAngle = Angle(degrees: angle + baseAngle)
        
        return Path { path in
            path.addArc(center: center, radius: radius, startAngle: Angle(degrees: baseAngle), endAngle: endAngle, clockwise: false)
        }
    }
}

struct RingView: View {
    var size: CGFloat
    var color: Color
    var progress: Double
    var lineWidth: CGFloat
    var body: some View {
        
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle.init(lineWidth: lineWidth, lineCap: .round))
                    .opacity(0.2)
                    .foregroundColor(color)
                RingShape(angle: progress * 360)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .fill(color)
                    
                if progress > 1 {
                    let offsetRadius = geometry.size.width / 2
                    
                    let angleForFinalSegment = -CGFloat(Double.pi / 2) + CGFloat(progress.truncatingRemainder(dividingBy: 1)) * (CGFloat(Double.pi))
                    let angleForOffsetInRadians = angleForFinalSegment + CGFloat(Double.pi / 2)
                    let relativeXOffset = cos(angleForOffsetInRadians)
                    let relativeYOffset = sin(angleForOffsetInRadians)
                    let xOffset = relativeXOffset * 7
                    let yOffset = relativeYOffset * 7
                    Circle()
                        .fill(color)
                        .frame(width: lineWidth,
                               height: lineWidth,
                               alignment: .center)
                        .offset(x: offsetRadius * cos(angleForFinalSegment),
                                y: offsetRadius * sin(angleForFinalSegment))
                        .shadow(color: Color.black.opacity(0.3),
                                radius: 4,
                                x: xOffset,
                                y: yOffset)
                }
            }
        }
        .padding(.all, lineWidth / 2)
        .frame(width: size, height: size)
    }

}

struct RingView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            RingView(size: 140, color: Color.green, progress: 0.97, lineWidth: 20)
            RingView(size: 140, color: Color.yellow, progress: 1.5, lineWidth: 20)
            RingView(size: 125, color: Color.pink, progress: 0.75, lineWidth: 20)
            RingView(size: 50, color: Color.yellow, progress: 0.5, lineWidth: 8)
                .preferredColorScheme(.dark)
        }.previewLayout(.fixed(width: 150, height: 150))
    }
}
