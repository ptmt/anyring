import SwiftUI

struct RingDashboard: View {
    let size: CGFloat
    @ObservedObject var ring1: RingViewModel
    @ObservedObject var ring2: RingViewModel
    @ObservedObject var ring3: RingViewModel
    var days = 3
    var shape: RingShape = .circle

    var body: some View {
        VStack(spacing: 24) {
            TripleRingView(size: size, ring1: ring1.snapshot(), ring2: ring2.snapshot(),
                           ring3: ring3.snapshot(), shape: shape)
                .accessibilityHidden(true)
            VStack(spacing: 14) {
                metric(ring1)
                metric(ring2)
                metric(ring3)
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

    private func metric(_ ring: RingViewModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text(ring.name).font(.headline)
                } icon: {
                    Circle().fill(ring.configuration.appearance.mainColor.color).frame(width: 9, height: 9)
                }
                Spacer(minLength: 8)
                Text("\(ring.progress.description) \(ring.units)")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.primary)
            }
            if let error = ring.error {
                Text(error.localizedDescription).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
