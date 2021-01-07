//
//  AnyRingApp.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import SwiftUI

@main
struct AnyRingApp: App {
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    var onReload: (() -> Void)?
    override init() {
    }
    
    func handleUserActivity(_ userInfo: [AnyHashable : Any]?) {
        print(">> handleUserActivity", userInfo)
    }
}
