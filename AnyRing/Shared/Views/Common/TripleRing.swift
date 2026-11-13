import Foundation
import SwiftUI

enum RingShape: String, Codable, CaseIterable, Identifiable, Sendable {
    case roundedSquare, circle, squircle, capsule, triangle, diamond, pentagon, hexagon, star, heart, rectangular

    var id: String { rawValue }
    var name: String {
        switch self {
        case .roundedSquare: "Rounded Square"
        case .circle: "Circle"
        case .squircle: "Squircle"
        case .capsule: "Capsule"
        case .triangle: "Triangle"
        case .diamond: "Diamond"
        case .pentagon: "Pentagon"
        case .hexagon: "Hexagon"
        case .star: "Star"
        case .heart: "Heart"
        case .rectangular: "Square"
        }
    }
    var isPointed: Bool { [.triangle, .diamond, .pentagon, .hexagon, .star, .heart].contains(self) }

    init(from decoder: Decoder) throws {
        self = Self(rawValue: try decoder.singleValueContainer().decode(String.self)) ?? .roundedSquare
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct RingSnapshot: Codable, Sendable {
    let progress: Double
    let mainColor: CodableColor
    var gradient: Bool = false
    var secondaryColor: CodableColor? = nil
    var outerGlow: Bool = true
    var innerGlow: Bool = false

    /// Preserve over-goal progress without converting NaN/Infinity to Int or overflowing.
    var percentageText: String {
        guard progress.isFinite else { return "—" }
        let percentage = max(0, progress) * 100
        guard percentage.isFinite else { return "—" }
        return percentage.formatted(.number.precision(.fractionLength(0)).rounded(rule: .towardZero)) + "%"
    }
}

/// Measures the contour so equal progress covers equal distance, including curved shapes.
struct RingContour: Sendable {
    let points: [CGPoint]
    let distances: [Double]
    let length: Double
    let center: CGPoint

    init(shape: RingShape, rect: CGRect) {
        center = CGPoint(x: rect.midX, y: rect.midY)
        var unit = Self.unitPoints(for: shape).reduce(into: [CGPoint]()) { unique, point in
            if let last = unique.last, hypot(point.x - last.x, point.y - last.y) < 0.000001 { return }
            unique.append(point)
        }
        // Deduplication can retain a rounded endpoint instead of the exact closing point.
        unit[unit.count - 1] = unit[0]
        points = unit.map { CGPoint(x: rect.minX + $0.x * rect.width, y: rect.minY + $0.y * rect.height) }
        var accumulated = [0.0]
        for index in 1..<points.count {
            let dx = points[index].x - points[index - 1].x
            let dy = points[index].y - points[index - 1].y
            accumulated.append(accumulated[index - 1] + hypot(dx, dy))
        }
        distances = accumulated
        length = accumulated.last ?? 0
    }

    func point(at progress: Double) -> CGPoint {
        let amount = bounded(progress)
        if amount == 1 { return points.last! }
        let target = amount * length
        guard let index = distances.firstIndex(where: { $0 >= target }), index > 0 else { return points[0] }
        let segment = distances[index] - distances[index - 1]
        let fraction = segment > 0 ? (target - distances[index - 1]) / segment : 0
        return CGPoint(x: points[index - 1].x + (points[index].x - points[index - 1].x) * fraction,
                       y: points[index - 1].y + (points[index].y - points[index - 1].y) * fraction)
    }

    func tangent(at progress: Double) -> CGPoint {
        let fraction = progress.isFinite ? progress.truncatingRemainder(dividingBy: 1) : 0
        let before = point(at: fraction > 0.001 ? fraction - 0.001 : 1 + fraction - 0.001)
        let after = point(at: fraction < 0.999 ? fraction + 0.001 : fraction + 0.001 - 1)
        let dx = after.x - before.x, dy = after.y - before.y
        let distance = hypot(dx, dy)
        return distance > 0 ? CGPoint(x: dx / distance, y: dy / distance) : CGPoint(x: 1, y: 0)
    }

    func angleLocation(at progress: Double) -> Double {
        angleLocation(for: point(at: progress))
    }

    func angleLocation(for point: CGPoint) -> Double {
        let angle = atan2(point.y - center.y, point.x - center.x) + .pi / 2
        let fraction = angle / (.pi * 2)
        return fraction < 0 ? fraction + 1 : fraction
    }

    func path(to progress: Double) -> Path {
        let amount = bounded(progress)
        var path = Path()
        path.move(to: points[0])
        guard amount > 0 else { return path }
        let target = amount * length
        for index in 1..<points.count {
            if distances[index] >= target { path.addLine(to: point(at: amount)); break }
            path.addLine(to: points[index])
        }
        if amount == 1 { path.closeSubpath() }
        return path
    }

    func highlightPath(to progress: Double, offset: Double) -> Path {
        let amount = bounded(progress)
        let count = points.count - 1
        func edgePoint(_ index: Int) -> CGPoint {
            let point = points[index % count]
            let before = points[(index + count - 1) % count], after = points[(index + 1) % count]
            let incoming = hypot(point.x - before.x, point.y - before.y)
            let outgoing = hypot(after.x - point.x, after.y - point.y)
            let dx = (point.x - before.x) / incoming + (after.x - point.x) / outgoing
            let dy = (point.y - before.y) / incoming + (after.y - point.y) / outgoing
            let length = hypot(dx, dy)
            return CGPoint(x: point.x - dy / length * offset, y: point.y + dx / length * offset)
        }
        var path = Path()
        path.move(to: edgePoint(0))
        guard amount > 0 else { return path }
        let stop = amount * length
        for index in 1..<points.count {
            if distances[index] >= stop {
                let point = point(at: amount), tangent = tangent(at: amount)
                path.addLine(to: CGPoint(x: point.x - tangent.y * offset, y: point.y + tangent.x * offset))
                break
            }
            path.addLine(to: edgePoint(index))
        }
        if amount == 1 { path.closeSubpath() }
        return path
    }

    private func bounded(_ value: Double) -> Double { value.isFinite ? min(1, max(0, value)) : 0 }

    private static func unitPoints(for shape: RingShape) -> [CGPoint] {
        var points: [CGPoint]
        switch shape {
        case .circle, .squircle:
            points = (0..<240).map { index in
                let angle = -.pi / 2 + Double(index) * .pi * 2 / 240
                let exponent = shape == .squircle ? 0.5 : 1.0
                let x = cos(angle), y = sin(angle)
                return CGPoint(x: 0.5 + (x < 0 ? -1 : 1) * pow(abs(x), exponent) * 0.5,
                               y: 0.5 + (y < 0 ? -1 : 1) * pow(abs(y), exponent) * 0.5)
            }
        case .roundedSquare, .rectangular:
            let radius = shape == .roundedSquare ? 0.22 : 0.0
            points = [CGPoint(x: 0.5, y: 0)]
            for (x, y, start) in [(1 - radius, radius, -90.0), (1 - radius, 1 - radius, 0),
                                  (radius, 1 - radius, 90), (radius, radius, 180)] {
                for step in 0...24 {
                    let angle = (start + Double(step) * 90 / 24) * .pi / 180
                    points.append(CGPoint(x: x + cos(angle) * radius, y: y + sin(angle) * radius))
                }
            }
        case .capsule:
            points = [CGPoint(x: 0.5, y: 0)]
            for (centerY, startAngle, sweep) in [(0.34, -90.0, 90.0), (0.66, 0, 180), (0.34, 180, 90)] {
                for step in 0...60 {
                    let angle = (startAngle + Double(step) * sweep / 60) * .pi / 180
                    points.append(CGPoint(x: 0.5 + cos(angle) * 0.34, y: centerY + sin(angle) * 0.34))
                }
            }
        case .triangle, .diamond, .pentagon, .hexagon, .star:
            let sides: Int
            switch shape {
            case .triangle: sides = 3
            case .diamond: sides = 4
            case .pentagon: sides = 5
            case .hexagon: sides = 6
            default: sides = 10
            }
            points = (0..<sides).map { index in
                let angle = -.pi / 2 + Double(index) * .pi * 2 / Double(sides)
                let radius = shape == .star && index % 2 == 1 ? 0.29 : 0.5
                return CGPoint(x: 0.5 + cos(angle) * radius, y: 0.5 + sin(angle) * radius)
            }
        case .heart:
            points = [CGPoint(x: 0.5, y: 0.25)]
            let curves: [(CGPoint, CGPoint, CGPoint)] = [
                (.init(x: 0.65, y: 0), .init(x: 0.99, y: 0.10), .init(x: 0.95, y: 0.38)),
                (.init(x: 0.93, y: 0.60), .init(x: 0.65, y: 0.82), .init(x: 0.5, y: 0.96)),
                (.init(x: 0.35, y: 0.82), .init(x: 0.07, y: 0.60), .init(x: 0.05, y: 0.38)),
                (.init(x: 0.01, y: 0.10), .init(x: 0.35, y: 0), .init(x: 0.5, y: 0.25))
            ]
            for (a, b, end) in curves {
                let start = points.last!
                for step in 1...60 {
                    let t = Double(step) / 60, u = 1 - t
                    points.append(CGPoint(x: pow(u, 3) * start.x + 3 * u * u * t * a.x + 3 * u * t * t * b.x + pow(t, 3) * end.x,
                                          y: pow(u, 3) * start.y + 3 * u * u * t * a.y + 3 * u * t * t * b.y + pow(t, 3) * end.y))
                }
            }
        }
        points.append(points[0])
        return points
    }
}

/// The head wraps after a complete lap, while the already completed ring stays filled.
struct RingProgress: Sendable {
    let value: Double
    var coverage: Double { min(value, 1) }
    var head: Double { value >= 1 ? value.truncatingRemainder(dividingBy: 1) : value }
    var overflow: Double { value > 1 ? head : 0 }

    init(_ value: Double) { self.value = value.isFinite ? max(0, value) : 0 }

    func gradientLocation(at position: Double) -> Double {
        guard value > 0 else { return 0 }
        if value < 1 { return min(1, max(0, position / value)) }
        let difference = head - position
        if abs(difference) < 0.00000001 { return 1 }
        let remainder = difference.truncatingRemainder(dividingBy: 1)
        let behind = remainder < 0 ? remainder + 1 : remainder
        return min(1, max(0, 1 - behind))
    }
}

private struct RingPaint: Sendable {
    let snapshot: RingSnapshot
    let progress: RingProgress
    let start: CodableColor
    let startAlpha: Double

    init(snapshot: RingSnapshot, progress: RingProgress) {
        self.snapshot = snapshot; self.progress = progress
        start = snapshot.secondaryColor ?? snapshot.mainColor
        startAlpha = snapshot.secondaryColor?.alpha ?? snapshot.mainColor.alpha * 0.55
    }

    private var startColor: Color {
        Color(.sRGB, red: start.red, green: start.green, blue: start.blue, opacity: startAlpha)
    }

    func color(at position: Double) -> Color {
        guard snapshot.gradient else { return snapshot.mainColor.color }
        if progress.value < 1, position > progress.coverage { return startColor }
        let main = snapshot.mainColor
        let amount = progress.gradientLocation(at: position)
        return Color(.sRGB, red: start.red + (main.red - start.red) * amount,
                     green: start.green + (main.green - start.green) * amount,
                     blue: start.blue + (main.blue - start.blue) * amount,
                     opacity: startAlpha + (main.alpha - startAlpha) * amount)
    }

    func shading(for contour: RingContour) -> GraphicsContext.Shading {
        guard snapshot.gradient else { return .color(snapshot.mainColor.color) }
        // Map polar angles to measured contour distance. One fill avoids seams between segments.
        // Sample straight polygon edges too: angle changes nonlinearly along a straight edge.
        var stops = (0...240).map { index in
            let position = Double(index) / 240
            let location = index == 240 ? 1 : contour.angleLocation(at: position)
            return Gradient.Stop(color: color(at: position), location: location)
        }
        let headLocation = contour.angleLocation(at: progress.head)
        stops.append(.init(color: snapshot.mainColor.color, location: headLocation))
        let seamLocation: Double
        if progress.value < 1 {
            // Extend the tip color over its round cap before returning to the starting color.
            seamLocation = headLocation + min(0.02, (1 - headLocation) / 2)
            stops.removeAll { $0.location > headLocation && $0.location <= seamLocation }
            stops.append(.init(color: snapshot.mainColor.color, location: seamLocation))
        } else {
            seamLocation = headLocation
        }
        // Keep the starting cap in the secondary color; the shaded tip covers this seam.
        stops.append(.init(color: startColor, location: min(1, seamLocation + 0.00001)))
        stops.sort { $0.location < $1.location }
        return .conicGradient(Gradient(stops: stops), center: contour.center, angle: .degrees(-90))
    }
}

/// One progress value drives the stroke, its gradient, and its moving head.
struct RingDrawing: View {
    let snapshot: RingSnapshot
    let kind: RingShape
    let lineWidth: CGFloat
    let progress: Double
    var simplified = false

    var body: some View {
        let padding = max(2, lineWidth * (simplified ? 0.6 : 1.2))
        Canvas { context, size in
            let inset = padding + lineWidth / 2 + 0.5
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: inset, dy: inset)
            guard rect.width > 0, rect.height > 0 else { return }
            let contour = RingContour(shape: kind, rect: rect)
            let state = RingProgress(progress)
            let paint = RingPaint(snapshot: snapshot, progress: state)
            let style = StrokeStyle(lineWidth: lineWidth, lineCap: kind == .rectangular ? .butt : .round,
                                    lineJoin: kind == .rectangular ? .miter : .round)
            context.stroke(contour.path(to: 1), with: .color(snapshot.mainColor.color.opacity(0.13)), style: style)
            guard state.value > 0 else { return }
            let arc = contour.path(to: state.coverage)
            let outline = arc.strokedPath(style)

            if snapshot.outerGlow {
                var halo = context
                halo.addFilter(.shadow(color: snapshot.mainColor.color.opacity(simplified ? 0.18 : 0.35),
                                       radius: lineWidth * (simplified ? 0.18 : 0.42), options: .shadowOnly))
                halo.drawLayer { layer in drawStroke(in: &layer, contour: contour, to: state.coverage, paint: paint, style: style) }
            }
            context.drawLayer { layer in drawStroke(in: &layer, contour: contour, to: state.coverage, paint: paint, style: style) }

            // Shade the filled tube, avoiding the internal subpaths of a stroked polygon.
            context.fill(outline, with: .linearGradient(Gradient(colors: [.white.opacity(snapshot.innerGlow ? 0.10 : 0.025), .clear, .black.opacity(0.06)]),
                         startPoint: .init(x: rect.minX, y: rect.minY), endPoint: .init(x: rect.maxX, y: rect.maxY)))
            if snapshot.innerGlow {
                var inner = context
                inner.clip(to: outline)
                inner.addFilter(.blur(radius: max(0.4, lineWidth * 0.08)))
                inner.stroke(contour.highlightPath(to: state.coverage, offset: -lineWidth * 0.40),
                             with: .color(.white.opacity(0.30)),
                             style: StrokeStyle(lineWidth: lineWidth * 0.13, lineCap: .round, lineJoin: .round))
            }

            drawHead(in: &context, contour: contour, state: state)
        }
        .padding(-padding) // Reserve real drawing space for halos beyond the stroke bounds.
    }

    private func drawStroke(in context: inout GraphicsContext, contour: RingContour, to amount: Double,
                            paint: RingPaint, style: StrokeStyle) {
        context.fill(contour.path(to: amount).strokedPath(style), with: paint.shading(for: contour))
    }

    private func drawHead(in context: inout GraphicsContext, contour: RingContour, state: RingProgress) {
        let point = contour.point(at: state.head)
        let tangent = contour.tangent(at: state.head)
        let normal = CGPoint(x: -tangent.y, y: tangent.x)
        let rect = CGRect(x: point.x - lineWidth / 2, y: point.y - lineWidth / 2, width: lineWidth, height: lineWidth)
        let head = kind == .rectangular ? Path(rect) : Path(ellipseIn: rect)
        let main = snapshot.mainColor.color
        var shadow = context
        shadow.addFilter(.shadow(color: .black.opacity(simplified ? 0.12 : 0.28), radius: lineWidth * 0.18,
                                 x: tangent.x * lineWidth * 0.18, y: tangent.y * lineWidth * 0.18, options: .shadowOnly))
        shadow.fill(head, with: .color(main))
        context.fill(head, with: .color(main))
        var highlight = context
        highlight.clip(to: head)
        highlight.fill(head, with: .linearGradient(Gradient(colors: [.white.opacity(snapshot.innerGlow ? 0.30 : 0.16), .clear, .black.opacity(0.08)]),
                        startPoint: .init(x: point.x - normal.x * lineWidth / 2, y: point.y - normal.y * lineWidth / 2),
                        endPoint: .init(x: point.x + normal.x * lineWidth / 2, y: point.y + normal.y * lineWidth / 2)))
        context.stroke(head, with: .color(.white.opacity(snapshot.innerGlow ? 0.28 : 0.10)), lineWidth: max(0.4, lineWidth * 0.04))
    }
}

/// Canvas uses a display timeline so every intermediate stroke is actually redrawn.
struct RingMotion: Equatable, Sendable {
    let from: Double
    let to: Double
    let start: Date
    let duration: TimeInterval

    static func fixed(_ value: Double) -> Self {
        Self(from: value, to: value, start: .distantPast, duration: 0)
    }

    func value(at date: Date) -> Double {
        guard duration > 0 else { return to }
        let fraction = min(1, max(0, date.timeIntervalSince(start) / duration))
        if fraction == 1 { return to }
        let eased = fraction * fraction * (3 - 2 * fraction)
        return from + (to - from) * eased
    }
}

struct ShapeProgressView: View {
    let size: CGFloat
    let snapshot: RingSnapshot
    let lineWidth: CGFloat
    let kind: RingShape
    var simplified: Bool
    var animationDelay: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var motion = RingMotion.fixed(0)
    @State private var animating = false
    @State private var targetProgress: Double
    @State private var ready = false

    init(size: CGFloat, snapshot: RingSnapshot, lineWidth: CGFloat, kind: RingShape,
         simplified: Bool = false, animationDelay: Double = 0) {
        self.size = size; self.snapshot = snapshot; self.lineWidth = lineWidth; self.kind = kind
        self.simplified = simplified; self.animationDelay = animationDelay
        _targetProgress = State(initialValue: RingProgress(snapshot.progress).value)
    }

    var body: some View {
        Group {
            if simplified || reduceMotion {
                drawing(progress: RingProgress(snapshot.progress).value)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / 60, paused: !animating)) { timeline in
                    drawing(progress: motion.value(at: timeline.date))
                }
            }
        }
            .task(id: kind) {
                guard !simplified, !reduceMotion else { ready = true; return }
                ready = false
                motion = .fixed(0)
                animating = false
                do { try await Task.sleep(for: .seconds(0.07 + animationDelay)) }
                catch { return }
                ready = true
                move(to: targetProgress, duration: 1.15)
            }
            .task(id: motion) {
                guard animating else { return }
                let remaining = motion.start.addingTimeInterval(motion.duration).timeIntervalSinceNow
                do { try await Task.sleep(for: .seconds(max(0, remaining))) }
                catch { return }
                motion = .fixed(targetProgress)
                animating = false
            }
            .onChange(of: snapshot.progress, initial: true) { _, value in
                targetProgress = RingProgress(value).value
                guard ready else { return }
                move(to: targetProgress, duration: simplified || reduceMotion ? 0 : 0.65)
            }
            .onChange(of: reduceMotion) { _, reduced in
                if reduced { move(to: targetProgress, duration: 0) }
            }
    }

    private func drawing(progress: Double) -> some View {
        RingDrawing(snapshot: snapshot, kind: kind, lineWidth: lineWidth, progress: progress, simplified: simplified)
            .frame(width: size, height: size)
    }

    private func move(to value: Double, duration: TimeInterval) {
        let now = Date()
        let current = motion.value(at: now)
        guard duration > 0, current != value else {
            motion = .fixed(value)
            animating = false
            return
        }
        motion = RingMotion(from: current, to: value, start: now, duration: duration)
        animating = true
    }
}

struct TripleRingView: View {
    let size: CGFloat
    let ring1: RingSnapshot
    let ring2: RingSnapshot
    let ring3: RingSnapshot
    var simplified = false
    var shape: RingShape = .roundedSquare

    var body: some View {
        let lineWidth = size / (shape.isPointed ? 20 : 12)
        ZStack {
            ShapeProgressView(size: size, snapshot: ring1, lineWidth: lineWidth, kind: shape, simplified: simplified)
            ShapeProgressView(size: size * 0.74, snapshot: ring2, lineWidth: lineWidth, kind: shape, simplified: simplified, animationDelay: 0.06)
            ShapeProgressView(size: size * 0.48, snapshot: ring3, lineWidth: lineWidth, kind: shape, simplified: simplified, animationDelay: 0.12)
        }
        .frame(width: size, height: size)
    }
}

/// Complications can mask their entire canvas to a circle, including square-shaped rings.
struct CircularRingGraphic: View {
    let diameter: CGFloat
    let rings: RingWrapper<RingSnapshot>
    var shape: RingShape = .roundedSquare

    var body: some View {
        TripleRingView(size: fittedSize, ring1: rings.first, ring2: rings.second, ring3: rings.third,
                       simplified: true, shape: shape)
            .frame(width: diameter, height: diameter)
    }

    private var fittedSize: CGFloat {
        guard diameter > 3 else { return 0 }
        let width = 1.0 / (shape.isPointed ? 20 : 12)
        let contour = RingContour(shape: shape, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
        let radius = contour.points.map { hypot($0.x - 0.5, $0.y - 0.5) }.max() ?? 0.5
        // Mitered square corners extend farther than round joins. Include the halo and pixel clearance.
        let stroke = shape == .rectangular ? width / sqrt(2) : width / 2
        let reach = radius * (1 - width) + stroke + width * 0.75
        return diameter * min(1, (0.5 - 1.5 / diameter) / reach)
    }
}
