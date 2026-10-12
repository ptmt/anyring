import SwiftUI

@main
struct AnyRingApp: App {
    @StateObject private var controller = AppController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: controller.viewModel)
                #if os(iOS)
                .environmentObject(controller.connectivity)
                #endif
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { controller.becameActive() }
        }
    }
}
