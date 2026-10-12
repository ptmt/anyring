import SwiftUI

struct RingCircleShape: Shape {
    var endAngle: Double
    var animatableData: Double {
        get { endAngle }
        set { endAngle = newValue }
    }
    static let baseAngle = 0.0
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: min(rect.width, rect.height) / 2,
                        startAngle: .degrees(-90), endAngle: .degrees(-90 + endAngle), clockwise: false)
        }
    }
}

struct RingView: View {
    let size: CGFloat
    let snapshot: RingSnapshot
    let lineWidth: CGFloat
    var simplified = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let progress = snapshot.progress.isFinite ? max(0, snapshot.progress) : 0
        let main = snapshot.mainColor.color
        let secondary = snapshot.gradient ? snapshot.secondaryColor?.color ?? main.opacity(0.5) : main
        ZStack {
            Circle().stroke(main.opacity(0.15), lineWidth: lineWidth)
            RingCircleShape(endAngle: min(progress, 1) * 360)
                .stroke(AngularGradient(colors: [secondary, main], center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .conditionalModifier(snapshot.outerGlow && !simplified, OuterGlow(main))
                .conditionalModifier(snapshot.innerGlow && !simplified, InnerGlow(main, size: size, lineWidth: lineWidth, progress: min(progress, 1)))
            if progress > 0 {
                Circle().fill(main).frame(width: lineWidth, height: lineWidth)
                    .shadow(color: .black.opacity(0.25), radius: 2)
                    .offset(y: -(size - lineWidth) / 2)
                    .rotationEffect(.degrees(progress.truncatingRemainder(dividingBy: 1) * 360))
            }
        }
        .padding(lineWidth / 2)
        .frame(width: size, height: size)
        .animation(simplified || reduceMotion ? nil : .easeInOut(duration: 0.35), value: snapshot.progress)
    }
}

extension View {
    func conditionalModifier<T: ViewModifier>(_ condition: Bool, _ modifier: T) -> some View {
        Group { if condition { self.modifier(modifier) } else { self } }
    }
}

extension Color {
    var codable: CodableColor { CodableColor(self) }
}
