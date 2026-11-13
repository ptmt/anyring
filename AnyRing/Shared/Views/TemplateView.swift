import SwiftUI

struct RingPalette: Identifiable, Sendable {
    let name: String
    let snapshots: RingWrapper<RingSnapshot>
    var id: String { name }

    static let all: [Self] = [
        palette("Aurora", [0x6D5EF5, 0x21C7D9, 0xFF7D8B]),
        palette("Ocean", [0x3478F6, 0x13B8A6, 0x8CE9F0], gradient: true),
        palette("Sunset", [0xF35E92, 0xFF9257, 0xF7C55A], gradient: true),
        palette("Forest", [0x158B67, 0x68B784, 0xB7D9A5]),
        palette("Arctic", [0x62CBDF, 0x6889E8, 0xB6A4EC]),
        palette("Ember", [0xE86137, 0xF19C54, 0xF8D197], gradient: true),
        palette("Berry", [0xB94D91, 0x855FD5, 0xD9A0DB]),
        palette("Citrus", [0x96C83C, 0xE8BF38, 0xF48B38]),
        palette("Lagoon", [0x087F9E, 0x22BDAA, 0x91DDC3], gradient: true),
        palette("Candy", [0xF08FC0, 0x7ABCEB, 0xB6A0E8]),
        palette("Graphite", [0x65748B, 0x97A4B6, 0xC5CDDB]),
        palette("Neon", [0xA553FF, 0x89E863, 0xFF4D9C], glow: true),
        palette("Moss", [0xF4FF3F, 0x71C13F, 0x255C26], gradient: true, secondaryColors: [0x223A26, 0x062419, nil]),
        palette("Rose Quartz", [0xFFE6E6, 0xFFABE1, 0xA685E2], glow: true),
        palette("Golden Hour", [0xFDD489, 0xFFC074, 0xCCDFA2], gradient: true, secondaryColors: [0xB91D73, 0x11998E, 0x0083B0]),
        palette("Terracotta", [0x734046, 0xA05344, 0xE79E4F]),
        palette("Sea Glass", [0x9DDFD3, 0xDBF6E9, 0xFFDADA]),
        palette("Classic", [0x30C75A, 0xFF335F, 0xF4C400])
    ]

    private static func palette(_ name: String, _ colors: [UInt], gradient: Bool = false, glow: Bool = false, secondaryColors: [UInt?]? = nil) -> Self {
        Self(name: name, snapshots: RingWrapper(colors.enumerated().map { index, hex in
            let enabled = gradient && (secondaryColors == nil || secondaryColors?[index] != nil)
            let secondary = secondaryColors?[index].map { Color(hex: $0).codable } ?? (enabled ? Color(hex: hex).darker(by: 20)?.codable : nil)
            return RingSnapshot(progress: [0.85, 0.65, 0.45][index], mainColor: Color(hex: hex).codable,
                         gradient: enabled, secondaryColor: secondary,
                         outerGlow: glow, innerGlow: glow)
        }))
    }
}

struct TemplatesView: View {
    var shape: RingShape = .roundedSquare
    var onSelect: ((RingWrapper<RingSnapshot>) -> Void)?

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 14) {
                ForEach(RingPalette.all) { palette in
                    Button { onSelect?(palette.snapshots) } label: {
                        VStack(spacing: 8) {
                            TripleRingView(size: 62, ring1: palette.snapshots.first, ring2: palette.snapshots.second,
                                           ring3: palette.snapshots.third, simplified: true, shape: shape)
                            Text(palette.name).font(.caption).foregroundStyle(.primary)
                        }
                        .frame(width: 86).padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(palette.name) palette")
                    .accessibilityIdentifier("palette.\(palette.id)")
                }
            }
        }
        .scrollIndicators(.hidden)
        .accessibilityIdentifier("paletteCarousel")
    }

    static func snapshotForColor(_ color: Color) -> RingSnapshot {
        RingSnapshot(progress: 0.8, mainColor: color.codable, outerGlow: false)
    }
    static func snapshotForColorWithGlow(_ color: Color) -> RingSnapshot {
        RingSnapshot(progress: 0.8, mainColor: color.codable, outerGlow: true, innerGlow: true)
    }
    static func snapshotGradients(_ color: Color, _ secondary: Color) -> RingSnapshot {
        RingSnapshot(progress: 0.8, mainColor: color.codable, gradient: true, secondaryColor: secondary.codable, outerGlow: false)
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB, red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255, blue: Double(hex & 0xff) / 255, opacity: alpha)
    }
}
