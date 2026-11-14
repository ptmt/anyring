// Synthetic visual fixtures only. Compile with the production TripleRing.swift and CodableColor.swift.
import SwiftUI
import AppKit

// The standalone renderer needs only this storage-free generic container.
struct RingWrapper<T> {
    let all: [T]
    init(_ all: [T]) { self.all = all }
    var first: T { all[0] }
    var second: T { all[1] }
    var third: T { all[2] }
}

@main @MainActor
struct RingEndpointProbe {
    static func snapshot(_ index: Int, _ progress: Double, glow: Bool = false) -> RingSnapshot {
        let colors: [Color] = [Color(red: 0.99, green: 0.16, blue: 0.34), Color(red: 1, green: 0.60, blue: 0), Color(red: 1, green: 0.80, blue: 0)]
        let secondary: [Color] = [colors[0], Color(red: 0.65, green: 0.29, blue: 0), Color(red: 0.66, green: 0.48, blue: 0)]
        return RingSnapshot(progress: progress, mainColor: CodableColor(colors[index]), gradient: index > 0,
                            secondaryColor: CodableColor(secondary[index]), outerGlow: glow)
    }

    static func fixture(shape: RingShape = .roundedSquare, size: CGFloat = 300, values: [Double] = [0.48, 0.50, 0.97], simplified: Bool = false) -> some View {
        let width = size / (shape.isPointed ? 20 : 12)
        return ZStack {
            ForEach(0..<3) { index in
                let side = size * [1.0, 0.74, 0.48][index]
                RingDrawing(snapshot: snapshot(index, values[index]), kind: shape, lineWidth: width, progress: values[index], simplified: simplified)
                    .frame(width: side, height: side)
            }
        }.frame(width: size, height: size).padding(30).background(.white)
    }

    static func save<V: View>(_ view: V, name: String, directory: URL, scale: CGFloat = 3) throws {
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let image = renderer.cgImage,
              let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else {
            fatalError("SwiftUI produced no pixels: \(name)")
        }
        try data.write(to: directory.appendingPathComponent(name + ".png"))
    }

    static func main() throws {
        let directory = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try save(fixture(), name: "synthetic-rounded-square", directory: directory)
        for shape in RingShape.allCases {
            try save(fixture(shape: shape), name: "synthetic-\(shape.rawValue)", directory: directory)
        }
        for value in [0.001, 0.49, 0.51, 0.53, 0.95, 0.97, 0.99, 1.0, 1.01, 1.25] {
            try save(fixture(values: [value, value, value]), name: "synthetic-progress-\(value)", directory: directory)
        }
        let start = Date(timeIntervalSince1970: 1000)
        for frame in 0...30 {
            let values = [0.48, 0.50, 1.25].map { target in
                RingMotion(from: 0, to: target, start: start, duration: 1).value(at: start.addingTimeInterval(Double(frame) / 30))
            }
            try save(fixture(values: values), name: String(format: "synthetic-motion-%02d", frame), directory: directory, scale: 2)
        }
        print("Rendered production SwiftUI Canvas fixtures to \(directory.path)")
    }
}
