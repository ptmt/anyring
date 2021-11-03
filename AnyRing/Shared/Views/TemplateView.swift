//
//  TemplateView.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 28.12.2020.
//

import Foundation
import SwiftUI



struct TemplatesView: View {
    static let defaultProgress = 1.5
    static func snapshotForColor(_ color: Color) -> RingSnapshot {
        RingSnapshot(progress: TemplatesView.defaultProgress, mainColor: CodableColor(color), gradient: false, outerGlow: false)
    }
    static func snapshotForColorWithGlow(_ color: Color) -> RingSnapshot {
        RingSnapshot(progress: TemplatesView.defaultProgress, mainColor: CodableColor(color), gradient: false, outerGlow: true, innerGlow: true)
    }

    static func snapshotGradients(_ color: Color, _ secondary: Color) -> RingSnapshot {
        RingSnapshot(progress: TemplatesView.defaultProgress, mainColor: CodableColor(color), gradient: true, secondaryColor: CodableColor(secondary), outerGlow: false)
    }
    
    let snapshots: [RingWrapper<RingSnapshot>] = [
        RingWrapper([
            TemplatesView.snapshotGradients(Color(hex: 0xf4ff3f), Color(hex: 0x223a26)),
            TemplatesView.snapshotGradients(Color(hex: 0x71c13f), Color(hex: 0x062419)),
            TemplatesView.snapshotForColor(Color(hex: 0x255c26))
        ]),
        RingWrapper([
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xaf3dff)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xa8ff78)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xff3b94))
        ]),
        RingWrapper([
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xffe6e6)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xffabe1)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xa685e2))
        ]),
        RingWrapper([
            TemplatesView.snapshotGradients(Color.init(hex: 0xfdd489),
                              Color.init(hex: 0xb91d73)),
            TemplatesView.snapshotGradients(Color.init(hex: 0xffc074),
                              Color.init(hex: 0x11998e)),
            TemplatesView.snapshotGradients(Color.init(hex: 0xccdfa2),
                              Color.init(hex: 0x0083B0)),
        ]),
        RingWrapper([
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0x734046)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xa05344)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xe79e4f))
        ]),
        RingWrapper([
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0x9ddfd3)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xdbf6e9)),
            TemplatesView.snapshotForColorWithGlow(Color.init(hex: 0xffdada))
        ]),
    ]
    var onSelect: ((RingWrapper<RingSnapshot>) -> Void)? = nil
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(0 ..< snapshots.count) { i in
                    let ring = snapshots[i]
                    TripleRingView(size: 45,
                                   ring1: ring.first,
                                   ring2: ring.second,
                                   ring3: ring.third,
                                   simplified: true,
                                   shape: .rectangular).onTapGesture {
                                    onSelect?(ring)
                                   }.drawingGroup()
                }
            }
        }
    }
}

// https://stackoverflow.com/questions/56874133/use-hex-color-in-swiftui
extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

struct TemplateView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            TemplatesView()
            TemplatesView().preferredColorScheme(.dark)
        }.previewLayout(.fixed(width: 600, height: 100))
    }
}
