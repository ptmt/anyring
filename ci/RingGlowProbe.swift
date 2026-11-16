// Synthetic fixtures; compiles the production renderer, never accesses HealthKit/preferences.
import SwiftUI
import AppKit

struct RingWrapper<T> {
    let list: [T]
    init(_ list: [T]) { self.list = list }
    var first: T { list[0] }
    var second: T { list[1] }
    var third: T { list[2] }
}

@main @MainActor
struct RingGlowProbe {
    static func main() throws {
        let output = URL(fileURLWithPath: CommandLine.arguments[1])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for shape in RingShape.allCases {
            for dark in [false, true] {
                for mode in 0..<4 {
                    let snapshot = RingSnapshot(progress: 0.65,
                        mainColor: CodableColor(Color(red: 0.616, green: 0.875, blue: 0.827)),
                        outerGlow: mode == 1 || mode == 3, innerGlow: mode >= 2)
                    let drawing = RingDrawing(snapshot: snapshot, kind: shape, lineWidth: shape.isPointed ? 9.6 : 16, progress: 0.65)
                        .frame(width: 192, height: 192).padding(32)
                        .background(dark ? Color.black : Color.white)
                    let renderer = ImageRenderer(content: drawing)
                    renderer.scale = 2
                    guard let image = renderer.cgImage,
                          let bytes = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]) else { fatalError("Missing pixels") }
                    let name = "\(shape.rawValue)-\(dark ? "dark" : "light")-\(["off", "outer", "inner", "both"][mode]).png"
                    try bytes.write(to: output.appendingPathComponent(name))
                }
            }
        }
        print("Rendered 11 shapes × 2 backgrounds × 4 effect combinations from production RingDrawing")
    }
}
