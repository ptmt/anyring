import SwiftUI

struct RectangularShape: Shape {
    var progress: Double
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    nonisolated static func point(for progress: Double) -> CGPoint {
        let p = (progress.isFinite ? max(0, min(1, progress)) : 0) * 4
        switch p {
        case ..<0.5: return CGPoint(x: 0.5 + p, y: 0)
        case ..<1.5: return CGPoint(x: 1, y: p - 0.5)
        case ..<2.5: return CGPoint(x: 2.5 - p, y: 1)
        case ..<3.5: return CGPoint(x: 0, y: 3.5 - p)
        default: return CGPoint(x: p - 3.5, y: 0)
        }
    }

    func path(in rect: CGRect) -> Path {
        let bounded = progress.isFinite ? max(0, min(1, progress)) : 0
        return Path { path in
            path.move(to: CGPoint(x: rect.midX, y: rect.minY))
            for boundary in [0.125, 0.375, 0.625, 0.875, 1.0] {
                let point = Self.point(for: min(boundary, bounded))
                path.addLine(to: CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height))
                if bounded <= boundary { break }
            }
        }
    }
}

struct RectangularView: View {
    let size: CGFloat
    let snapshot: RingSnapshot
    let lineWidth: CGFloat
    var simplified = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let progress = snapshot.progress.isFinite ? max(0, snapshot.progress) : 0
        let main = snapshot.mainColor.color
        let secondary = snapshot.gradient ? snapshot.secondaryColor?.color ?? main.opacity(0.5) : main
        let point = RectangularShape.point(for: progress <= 1 ? progress : progress.truncatingRemainder(dividingBy: 1))
        ZStack {
            Rectangle().stroke(main.opacity(0.15), lineWidth: lineWidth)
            RectangularShape(progress: min(progress, 1))
                .stroke(AngularGradient(colors: [secondary, main], center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt, lineJoin: .miter))
                .conditionalModifier(snapshot.outerGlow && !simplified, OuterGlow(main))
                .conditionalModifier(snapshot.innerGlow && !simplified, InnerGlow(main, size: size, lineWidth: lineWidth, progress: min(progress, 1)))
            if progress > 0 {
                Rectangle().fill(main).frame(width: lineWidth, height: lineWidth)
                    .shadow(color: .black.opacity(0.25), radius: 2)
                    .offset(x: (point.x - 0.5) * (size - lineWidth), y: (point.y - 0.5) * (size - lineWidth))
            }
        }
        .padding(lineWidth / 2)
        .frame(width: size, height: size)
        .animation(simplified || reduceMotion ? nil : .easeInOut(duration: 0.35), value: snapshot.progress)
    }
}
