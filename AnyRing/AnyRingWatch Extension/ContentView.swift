//
//  ContentView.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height) - 20
            TripleRingView(size: size,
                           ring1: .init(progress: 0.5, color: Color.green),
                           ring2: .init(progress: 1.5, color: Color.yellow),
                           ring3: .init(progress: 0.4, color: Color.blue))
                .padding(.all, 10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
