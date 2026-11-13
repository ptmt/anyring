import SwiftUI

struct RingDashboard: View {
    let size: CGFloat
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    var days = 3
    var shape: RingShape = .roundedSquare

    var body: some View {
        VStack(spacing: 24) {
            TripleRingView(size: size, ring1: ring1.snapshot(), ring2: ring2.snapshot(),
                           ring3: ring3.snapshot(), shape: shape)
                .accessibilityHidden(true)
            VStack(spacing: 16) {
                RingMetricView(ring: ring1)
                Divider()
                RingMetricView(ring: ring2)
                Divider()
                RingMetricView(ring: ring3)
            }
            if [ring1, ring2, ring3].allSatisfy({ $0.progress.empty && !$0.isRefreshing }) {
                Text("No health data yet. If you expected data, check AnyProgress’s access in Apple Health.")
                    .font(.footnote).foregroundStyle(.secondary)
                #if os(iOS)
                Link("Open Apple Health", destination: URL(string: "x-apple-health://")!)
                #endif
            }
            Text(days == 1 ? "Today" : "Today and the previous \(days - 1) days")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

}
