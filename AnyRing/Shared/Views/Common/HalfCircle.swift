//
//  HalfCircle.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 27.12.2020.
//

import Foundation
import SwiftUI

struct HalfCircle : Shape {
   
    func path(in rect: CGRect) -> Path {
        var p = Path()
        
        let width = rect.width
        let height = rect.height
        let radius = min(width, height) / 2
        let center = CGPoint(x: width / 2, y: height / 2)

        p.addArc(
            center: center,
            radius: radius,
            startAngle:
                Angle(radians: Double.pi / 2 + 0.5), endAngle: Angle(radians: -Double.pi / 2 - 0.5), clockwise: true)

        return p
    }
}

struct HalfCircle_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            HalfCircle().fill(Color.red)
            HalfCircle().fill(Color.blue)
        }.previewLayout(.fixed(width: 100, height: 100))
    }
}
