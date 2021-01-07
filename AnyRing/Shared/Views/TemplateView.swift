//
//  TemplateView.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 28.12.2020.
//

import Foundation
import SwiftUI

private let defaultProgress = 1.5
private func snapshotForColor(_ color: Color) -> RingSnapshot {
    RingSnapshot(progress: defaultProgress, mainColor: CodableColor(color), gradient: false, outerGlow: false)
}
private func snapshotForColorWithGlow(_ color: Color) -> RingSnapshot {
    RingSnapshot(progress: defaultProgress, mainColor: CodableColor(color), gradient: false, outerGlow: true, innerGlow: true)
}

private func snapshotGradients(_ color: Color, _ secondary: Color) -> RingSnapshot {
    RingSnapshot(progress: defaultProgress, mainColor: CodableColor(color), gradient: true, secondaryColor: CodableColor(secondary), outerGlow: false)
}

struct TemplatesView: View {
    
    let snapshots: [RingWrapper<RingSnapshot>] = [
        RingWrapper([
            snapshotForColor(Color.red),
            snapshotForColor(Color.green),
            snapshotForColor(Color.blue)
        ]),
        RingWrapper([
            snapshotForColorWithGlow(Color.init(hex: 0xaf3dff)),
            snapshotForColorWithGlow(Color.init(hex: 0xa8ff78)),
            snapshotForColorWithGlow(Color.init(hex: 0xff3b94))
        ]),
        RingWrapper([
            snapshotForColorWithGlow(Color.init(hex: 0xffe6e6)),
            snapshotForColorWithGlow(Color.init(hex: 0xffabe1)),
            snapshotForColorWithGlow(Color.init(hex: 0xa685e2))
        ]),
        RingWrapper([
            snapshotGradients(Color.init(hex: 0xf953c6),
                              Color.init(hex: 0xb91d73)),
            snapshotGradients(Color.init(hex: 0xa8ff78),
                              Color.init(hex: 0x11998e)),
            snapshotGradients(Color.init(hex: 0x00B4DB),
                              Color.init(hex: 0x0083B0)),
        ]),
        RingWrapper([
            snapshotForColorWithGlow(Color.init(hex: 0x734046)),
            snapshotForColorWithGlow(Color.init(hex: 0xa05344)),
            snapshotForColorWithGlow(Color.init(hex: 0xe79e4f))
        ]),
        RingWrapper([
            snapshotForColorWithGlow(Color.init(hex: 0x9ddfd3)),
            snapshotForColorWithGlow(Color.init(hex: 0xdbf6e9)),
            snapshotForColorWithGlow(Color.init(hex: 0xffdada))
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
                                   simplified: true).onTapGesture {
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
