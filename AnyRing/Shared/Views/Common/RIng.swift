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
    var body: some View {
        ShapeProgressView(size: size, snapshot: snapshot, lineWidth: lineWidth, kind: .circle, simplified: simplified)
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
