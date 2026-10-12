import SwiftUI
import WatchKit
import WatchConnectivity

@main
struct AnyRingApp: App {
    @StateObject private var controller = AppController()
    @Environment(\.scenePhase) private var scenePhase
    @WKApplicationDelegateAdaptor(WatchAppDelegate.self) private var delegate

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView(viewModel: controller.viewModel, connectivity: controller.connectivity)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { controller.becameActive() }
        }
    }
}

@MainActor
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    private var pendingTasks: [WKWatchConnectivityRefreshBackgroundTask] = []
    private var observations: [NSKeyValueObservation] = []

    override init() {
        super.init()
        guard WCSession.isSupported() else { return }
        observations = [
            WCSession.default.observe(\.activationState, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.finishConnectivityTasks() }
            },
            WCSession.default.observe(\.hasContentPending, options: [.new]) { [weak self] _, _ in
                Task { @MainActor in self?.finishConnectivityTasks() }
            }
        ]
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            if let connectivity = task as? WKWatchConnectivityRefreshBackgroundTask {
                pendingTasks.append(connectivity)
            } else if let snapshot = task as? WKSnapshotRefreshBackgroundTask {
                snapshot.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: .distantFuture, userInfo: nil)
            } else {
                task.setTaskCompletedWithSnapshot(false)
            }
        }
        // Let the coordinator's queued main-actor receive callbacks persist their snapshots first.
        Task { @MainActor in
            await Task.yield()
            finishConnectivityTasks()
        }
    }

    private func finishConnectivityTasks() {
        guard WCSession.default.activationState == .activated, !WCSession.default.hasContentPending else { return }
        pendingTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }
        pendingTasks.removeAll()
    }
}
