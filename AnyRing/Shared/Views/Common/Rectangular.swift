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
    var body: some View {
        ShapeProgressView(size: size, snapshot: snapshot, lineWidth: lineWidth, kind: .rectangular, simplified: simplified)
    }
}
