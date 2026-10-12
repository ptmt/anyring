import SwiftUI

struct MainScreen: View {
    let rings: RingWrapper<RingViewModel>
    @EnvironmentObject private var viewModel: AnyRingViewModel
    #if os(iOS)
    @EnvironmentObject private var connectivity: WatchConnectivityCoordinator
    #endif

    var body: some View {
        Form {
            Section {
                RingDashboard(size: 210, ring1: rings.first, ring2: rings.second,
                              ring3: rings.third, days: viewModel.globalConfig.days, shape: .rectangular)
                    .padding(.vertical, 16)
            }
            Section("Tracking Period") {
                Picker("Days", selection: Binding(get: { viewModel.globalConfig.days }, set: viewModel.updatePeriod)) {
                    ForEach(Array(Set([1, 2, 3, 5, 7, viewModel.globalConfig.days])).sorted(), id: \.self) { days in
                        Text("\(days)").tag(days)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("trackingPeriod")
                Text("Track progress from the start of the first day through today.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Your Rings") {
                ringLink(rings.first, number: 1)
                ringLink(rings.second, number: 2)
                ringLink(rings.third, number: 3)
            }
            Section("Color Palettes") {
                TemplatesView { snapshots in
                    rings.first.updateFromSnapshot(snapshot: snapshots.first)
                    rings.second.updateFromSnapshot(snapshot: snapshots.second)
                    rings.third.updateFromSnapshot(snapshot: snapshots.third)
                }
                .padding(.vertical, 8)
            }
            #if os(iOS)
            Section("Apple Watch") {
                Label(connectivity.status, systemImage: "applewatch")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Settings sync automatically. Each device reads its own Apple Health data.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            #endif
        }
        .formStyle(.grouped)
    }

    private func ringLink(_ ring: RingViewModel, number: Int) -> some View {
        NavigationLink {
            Form { RingConfigurationView(ring: ring).environmentObject(viewModel) }
                .navigationTitle("Ring \(number)")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "circle.circle.fill")
                    .font(.title2).foregroundStyle(ring.configuration.appearance.mainColor.color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(ring.name).font(.headline)
                    Text("Ring \(number) · \(ring.units)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("ring\(number)")
    }
}
