import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AnyRingViewModel
    @State private var path: [RingID] = []
    #if os(iOS)
    @EnvironmentObject private var connectivity: WatchConnectivityCoordinator
    #endif

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if !viewModel.dataSource.isAvailable() {
                    ContentUnavailableView("Health Data Unavailable", systemImage: "heart.slash",
                                           description: Text("Apple Health is required to track your progress."))
                } else if viewModel.showingAlert {
                    ContentUnavailableView {
                        Label("Health Access Needed", systemImage: "heart")
                    } description: {
                        Text(viewModel.authorizationError ?? "Allow AnyProgress to read your selected metrics in Apple Health.")
                    } actions: {
                        Button("Try Again") { viewModel.updateProviders() }
                        #if os(iOS)
                        Link("Open Apple Health", destination: URL(string: "x-apple-health://")!)
                        #endif
                    }
                } else if let rings = viewModel.rings {
                    MainScreen(rings: rings)
                        .environmentObject(viewModel)
                        .refreshable { viewModel.refresh() }
                } else {
                    ProgressView("Loading your rings")
                }
            }
            .navigationDestination(for: RingID.self) { id in
                if let ring = viewModel.rings?.list.first(where: { $0.configuration.ring == id }) {
                    Form { RingConfigurationView(ring: ring).environmentObject(viewModel) }
                        .navigationTitle("Ring \(id.rawValue + 1)")
                }
            }
            .onOpenURL { url in
                guard let destination = WidgetDestination(url: url) else { return }
                switch destination {
                case .overview: path = []
                case .ring(let id): path = [id]
                }
            }
            .navigationTitle("AnyProgress")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh", systemImage: "arrow.clockwise") {
                        viewModel.refresh()
                        #if os(iOS)
                        connectivity.refresh()
                        #endif
                    }
                    .accessibilityIdentifier("refresh")
                }
            }
        }
    }
}
