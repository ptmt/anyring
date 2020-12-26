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
                           ring1: .init(progress: 1.5, mainColor: Color.green, secondaryColor: Color(#colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1))),
                           ring2: .init(progress: 1.5, mainColor: Color.yellow),
                           ring3: .init(progress: 0.4, mainColor: Color.blue))
                .padding(.all, 10)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
