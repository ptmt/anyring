//
//  Rectangular.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 08.01.2021.
//

import Foundation
import SwiftUI


struct RectangularShape: Shape {
    var progress: Double
    
    @State private var finalProgress: Double = 0
    
    var animatableData: Double {
        get { finalProgress }
        set { finalProgress = newValue }
    }
    
    static let segments = [
        CGPoint(x: 1.0, y: 0),
        CGPoint(x: 1.0, y: 1),
        CGPoint(x: 0, y: 1),
        CGPoint(x: 0, y: 0),
        CGPoint(x: 0.5, y: 0),
    ]
    
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        
        return Path { path in
            path.move(
                to: CGPoint(
                    x: width / 2,
                    y: 0
                )
            )
            
            var covered: Double = 0
            RectangularShape.segments.forEach { segment in
                
                
                //                let endPointX = width * segment.x
                //                let rectWidth = endPointX - path.currentPoint!.x >= 0 ? max(lineWidth, abs(endPointX - path.currentPoint!.x)) : min(-lineWidth, endPointX - path.currentPoint!.x)
                //                let endPointY = height * segment.y
                //                let rectHeight = endPointY - path.currentPoint!.y >= 0 ? max(lineWidth, abs(endPointY - path.currentPoint!.y)) :  min(-lineWidth, endPointY - path.currentPoint!.y)
                //                let isHorizontal = rectWidth > rectHeight
                //
                //
                //                path.addRect(.init(origin: path.currentPoint!, size:
                //                                    .init(width: rectWidth,
                //                                          height: rectHeight)))
                //                let endPoint = CGPoint(x: isHorizontal ? endPointX - lineWidth : endPointX, y: isHorizontal ? endPointY : endPointY - lineWidth)
                //                print(">> draw size", rectWidth, rectHeight, "from", path.currentPoint, "to", endPoint)
                //                path.move(to: endPoint)
                let delta = covered == 0 || covered + 0.13 > 1 ? 0.25 / 2 : 0.25
                if (covered + delta <= progress) {
                    path.addLine(
                        to: CGPoint(
                            x: width * segment.x,
                            y: height * segment.y
                        )
                    )
                } else {
                    let finalDelta = CGFloat(progress - covered) / CGFloat(delta)
                    if (finalDelta > 0) {
                        let isHorizontal = abs(path.currentPoint!.x - segment.x * width) > 0.1
                        let x = isHorizontal ? path.currentPoint!.x + finalDelta * (width * segment.x - path.currentPoint!.x) : width * segment.x
                        let y = isHorizontal ? height * segment.y : path.currentPoint!.y - finalDelta * (path.currentPoint!.y - height * segment.y)
//                        print("current", path.currentPoint, isHorizontal, CGPoint(
//                            x: width * segment.x,
//                            y: height * segment.y
//                        ), "\n finalDelta=", progress, CGFloat(progress - covered), finalDelta, "\nx, y", x, y)
                        path.addLine(
                            to: CGPoint(
                                x: x,
                                y: y
                            )
                        )
                    }
                }
                covered = covered + delta
            }
        }
    }
}

//struct RectangularShape_Preview: PreviewProvider {
//    static let gradient = LinearGradient(gradient: Gradient(colors: [
//                                                                Color.green,
//                                                                Color.blue]),
//                                         startPoint: .leading,
//                                         endPoint: .trailing)
//    static var previews: some View {
//        Group {
//            RectangularShape(progress: 0.15).stroke(lineWidth: 20).fill(gradient)
//            RectangularShape(progress: 0.5).stroke(lineWidth: 20).fill(gradient)
//            RectangularShape(progress: 0.75).stroke(lineWidth: 20).fill(gradient)
//        }.previewLayout(.fixed(width: 250, height: 250))
//    }
//}

struct RectLineEndView: View {
    var progress: Double
    var offsetRadius: CGFloat
    var lineWidth: CGFloat
    var primaryColor: Color
    var innerGlow: Bool
    @State private var finalProgress: Double = 0
    
    var animatableData: Double {
        get { finalProgress }
        set { finalProgress = newValue }
    }
    
    var body: some View {
        var covered: Double = 0
        var offsetX: Double = 0
        var offsetY: Double = 0
        let width: Double = Double(offsetRadius * 2)
        let height: Double = Double(offsetRadius * 2)
        var i = 0
        var lastSegment: CGPoint = .zero
        while (covered < finalProgress) {
            i = i + 1
            RectangularShape.segments.forEach { segment in
                let delta = covered == 0 || covered.truncatingRemainder(dividingBy: 1.0) + 0.13 > 1 ? 0.25 / 2 : 0.25
                if (covered + delta <= finalProgress) {
                    offsetX = Double(segment.x) * width
                    offsetY = Double(segment.y) * height
                } else {
                    lastSegment = segment
                    let finalDelta = (finalProgress - covered) / delta
                    if (finalProgress - covered > 0) {
                        let isHorizontal = abs(offsetX - Double(segment.x) * width) > 0.1
                        let x = isHorizontal ?
                            offsetX + finalDelta * (width * Double(segment.x) - offsetX) :
                            width * Double(segment.x)
                        let y = isHorizontal ?
                            height * Double(segment.y) :
                            offsetY + finalDelta * (width * Double(segment.y) - offsetY)
                        offsetX = x
                        offsetY = y
                    }
                }
                covered = covered + delta
            }
        }
        return Rectangle()
            .fill(primaryColor)
            .frame(width: lineWidth,
                   height: lineWidth,
                   alignment: .top)
            .shadow(color: Color.black.opacity(0.4), radius: 3, x: lastSegment.x * 4, y: -lastSegment.y * 4)
            .offset(x: CGFloat(offsetX) - offsetRadius, y: CGFloat(offsetY) - offsetRadius)
            .onAppear(perform: {
                finalProgress = progress
            })
            .onChange(of: progress, perform: { value in
                finalProgress = value
            })
    }
}



struct RectangularView: View {
    var size: CGFloat
    var snapshot: RingSnapshot
    var lineWidth: CGFloat
    
    // improve fps by disabling animation and some glows
    var simplified = false
    
    private var primaryColor: Color {
        snapshot.mainColor.color
    }
    private var secondaryColor: Color? {
        snapshot.secondaryColor?.color
    }
    private var progress: Double {
        snapshot.progress
    }
    private var outerGlow: Bool {
        snapshot.outerGlow
    }
    private var innerGlow: Bool {
        snapshot.innerGlow
    }
    @State private var firstRender = true
    
    var body: some View {
        let baseAngle: Double = 0 // -(360 / 8)
        let angle: Double = progress * 360
        let gradientSecondaryColor = (secondaryColor ?? primaryColor.blend(with: UIColor(Color.primary)))
        let gradient = AngularGradient(gradient: Gradient(colors: [gradientSecondaryColor, primaryColor]), center: .center,
                                       startAngle: Angle(degrees: baseAngle),
                                       endAngle: Angle(degrees: angle  + baseAngle))
        
        let linearGradient = LinearGradient(gradient: Gradient(colors: [gradientSecondaryColor, primaryColor]),
                                            startPoint: .init(x: 0, y: 0),
                                            endPoint: .init(x: 1, y: 1))
        
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .stroke(style: StrokeStyle.init(lineWidth: lineWidth, lineCap: .round, lineJoin: .miter))
                    .fill(primaryColor)
                    .opacity(0.30)
                
                RectangularShape(progress: progress)
                    .stroke(style: StrokeStyle.init(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter))
                    .fill(gradient)
                    .animation(simplified ? nil : .easeInOut(duration: firstRender ? progress : 0.5))
                    .conditionalModifier(outerGlow && !simplified, OuterGlow(primaryColor))
                
                
                //  if progress > 1 {
                RectLineEndView(
                                        progress: progress,
                                        offsetRadius: geometry.size.width / 2,
                                        lineWidth: lineWidth,
                                        primaryColor: primaryColor,
                                        innerGlow: innerGlow)
                                        .animation(simplified ? nil : .easeInOut(duration: firstRender ? progress : 0.5))
                //  }
            }
        }
        .padding(.all, lineWidth / 2)
        .frame(width: size, height: size)
        .onChange(of: progress, perform: { value in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(progress) * 1000)) {
                firstRender = false
            }
        })
    }
}

struct RectangularView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            RectangularView(size: 140, snapshot: RingSnapshot(progress: 0.30, mainColor: Color.green.codable, gradient: true, secondaryColor: Color.blue.codable, outerGlow: false), lineWidth: 20.0)
            RectangularView(size: 240, snapshot: RingSnapshot(progress: 0.75, mainColor: Color.red.codable, gradient: false, outerGlow: false, innerGlow: true), lineWidth: 40.0).preferredColorScheme(.dark)
            RectangularView(size: 100, snapshot: RingSnapshot(progress: 1.5, mainColor: Color.pink.codable, gradient: false, outerGlow: false, innerGlow: false), lineWidth: 20.0)
                .preferredColorScheme(.dark)
        }.previewLayout(.fixed(width: 250, height: 250))
    }
}
