import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AnyRingViewModel
    @ObservedObject var connectivity: WatchConnectivityCoordinator

    var body: some View {
        ScrollView {
            if !viewModel.dataSource.isAvailable() {
                Text("Apple Health is unavailable").padding()
            } else if viewModel.showingAlert {
                Text(viewModel.authorizationError ?? "Allow AnyProgress to read your metrics in Health.")
                Button("Try Again") { viewModel.updateProviders() }
            } else if let rings = viewModel.rings {
                WatchDashboard(ring1: rings.first, ring2: rings.second, ring3: rings.third,
                               days: viewModel.globalConfig.days)
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

    var body: some View {
        VStack(spacing: 12) {
            TripleRingView(size: 140, ring1: ring1.snapshot(), ring2: ring2.snapshot(), ring3: ring3.snapshot(), shape: .rectangular)
                .padding(.vertical, 8).accessibilityHidden(true)
            metric(ring1)
            metric(ring2)
            metric(ring3)
            Text(days == 1 ? "Today" : "\(days)-day period").font(.caption2).foregroundStyle(.secondary)
        }
    }

    private func metric(_ ring: RingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(ring.name).font(.headline)
            Text("\(ring.progress.description) \(ring.units)").font(.body.monospacedDigit())
            if let error = ring.error { Text(error.localizedDescription).font(.caption2) }
        }
        .foregroundStyle(ring.configuration.appearance.mainColor.color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
    }
}
