import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AnyRingViewModel
    @ObservedObject var connectivity: WatchConnectivityCoordinator

    var body: some View {
        ScrollView {
            SyncStatusHeader(connectivity: connectivity).padding(.bottom, 4)
            if !viewModel.dataSource.isAvailable() {
                Text("Apple Health is unavailable").padding()
            } else if viewModel.showingAlert {
                Text(viewModel.authorizationError ?? "Allow AnyProgress to read your metrics in Health.")
                Button("Try Again") { viewModel.updateProviders() }
            } else if let rings = viewModel.rings {
                WatchDashboard(ring1: rings.first, ring2: rings.second, ring3: rings.third,
                               days: viewModel.globalConfig.days, shape: viewModel.globalConfig.shape)
            } else {
                ProgressView()
            }
            Text(connectivity.status).font(.caption2).foregroundStyle(.secondary)
                .multilineTextAlignment(.center).padding(.top, 8)
            Button("Refresh", systemImage: "arrow.clockwise") {
                viewModel.refresh()
                connectivity.refresh()
            }
            .padding(.top, 4)
        }
        .navigationTitle("AnyProgress")
    }
}

struct WatchDashboard: View {
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    let days: Int
    let shape: RingShape

    var body: some View {
        VStack(spacing: 12) {
            TripleRingView(size: 140, ring1: ring1.snapshot(), ring2: ring2.snapshot(), ring3: ring3.snapshot(), shape: shape)
                .padding(.vertical, 8).accessibilityHidden(true)
            RingMetricView(ring: ring1, compact: true)
            Divider()
            RingMetricView(ring: ring2, compact: true)
            Divider()
            RingMetricView(ring: ring3, compact: true)
            Text(days == 1 ? "Today" : "\(days)-day period").font(.caption2).foregroundStyle(.secondary)
        }
    }

}
