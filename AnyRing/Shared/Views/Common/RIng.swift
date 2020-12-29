//
//  RIng.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 19.12.2020.
//

import SwiftUI

struct RingShape: Shape {
    var endAngle: Double
    var animatableData: Double {
            get { endAngle }
            set { endAngle = newValue }
        }
    
    // We used to compensate the start
    static let baseAngle: Double = 0
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let radius = min(width, height) / 2
        let center = CGPoint(x: width / 2, y: height / 2)
        let endAngleNormalized = Angle(degrees: endAngle + RingShape.baseAngle)
        
        return Path { path in
            path.addArc(center: center,
                        radius: radius,
                        startAngle: Angle(degrees: RingShape.baseAngle),
                        endAngle: endAngleNormalized,
                        clockwise: false)
        }
    }
}

struct RingLineEndView: View {
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
        Circle()
            .fill(primaryColor)
            .frame(width: lineWidth,
                   height: lineWidth,
                   alignment: .center)
            .rotationEffect(.degrees(finalProgress * 360))
            .conditionalModifier(innerGlow, InnerGlow(primaryColor, size: lineWidth - 1, lineWidth: lineWidth - 1, progress: 1.0, halfCircle: true))
            .shadow(color: Color.black.opacity(0.2), radius: 3, x: 4, y: 0)
            .offset(x: 0, y: -offsetRadius)
            .rotationEffect(.degrees(finalProgress * 360))
            .onAppear(perform: {
                finalProgress = progress
            })
            .onChange(of: progress, perform: { value in
                finalProgress = value
            })
    }
}

struct RingView: View {
    var size: CGFloat
    var snapshot: RingSnapshot
    var lineWidth: CGFloat
    
    // improve fps by disabling animation and some glows
    var simplified = false
    
    private var primaryColor: Color {
        snapshot.mainColor
    }
    private var secondaryColor: Color? {
        snapshot.secondaryColor
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
                
                RingShape(endAngle: angle)
                    .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .fill(gradient)
                    .animation(simplified ? nil : .easeInOut(duration: firstRender ? progress : 0.5))
                    .conditionalModifier(outerGlow, OuterGlow(primaryColor, simplified: simplified))
                    .conditionalModifier(!simplified && innerGlow, InnerGlow(primaryColor, size: size, lineWidth: lineWidth, progress: progress))
                    .rotationEffect(.radians(-Double.pi / 2))
                   
              //  if progress > 1 {
                    RingLineEndView(
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
            RingView(size: 140, snapshot: RingSnapshot(progress: 1.5, mainColor: Color.green, gradient: true, secondaryColor: Color(#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1)), outerGlow: false), lineWidth: 20.0)
            RingView(size: 240, snapshot: RingSnapshot(progress: 1.75, mainColor: Color.red, gradient: false, outerGlow: false, innerGlow: true), lineWidth: 40.0).preferredColorScheme(.dark)
            RingView(size: 100, snapshot: RingSnapshot(progress: 0.75, mainColor: Color.pink, gradient: false, outerGlow: false, innerGlow: false), lineWidth: 20.0)
                .preferredColorScheme(.dark)
        }.previewLayout(.fixed(width: 250, height: 250))
    }
}
