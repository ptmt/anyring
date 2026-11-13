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
                #if os(iOS)
                SyncStatusHeader(connectivity: connectivity)
                #endif
                RingDashboard(size: 210, ring1: rings.first, ring2: rings.second,
                              ring3: rings.third, days: viewModel.globalConfig.days, shape: viewModel.globalConfig.shape)
                    .padding(.vertical, 16)
            }
            Section("Visualization") {
                NavigationLink {
                    ShapeSelectionView(selection: Binding(get: { viewModel.globalConfig.shape }, set: viewModel.updateShape),
                                       snapshots: RingWrapper(rings.list.map { $0.snapshot() }))
                } label: {
                    LabeledContent("Shape", value: viewModel.globalConfig.shape.name)
                }
                .accessibilityIdentifier("visualizationShape")
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
                TemplatesView(shape: viewModel.globalConfig.shape) { snapshots in
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


struct ShapeSelectionView: View {
    @Binding var selection: RingShape
    let snapshots: RingWrapper<RingSnapshot>

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 16) {
                ForEach(RingShape.allCases) { shape in
                    Button { selection = shape } label: {
                        VStack(spacing: 12) {
                            TripleRingView(size: 86, ring1: preview(snapshots.first, progress: 0.85),
                                           ring2: preview(snapshots.second, progress: 0.65), ring3: preview(snapshots.third, progress: 0.45),
                                           simplified: true, shape: shape)
                            HStack(spacing: 5) {
                                Text(shape.name).font(.subheadline)
                                if selection == shape { Image(systemName: "checkmark.circle.fill").foregroundStyle(.tint) }
                            }
                            .foregroundStyle(.primary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(.quaternary.opacity(selection == shape ? 0.7 : 0.3), in: RoundedRectangle(cornerRadius: 20))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(shape.name)
                    .accessibilityAddTraits(selection == shape ? .isSelected : [])
                    .accessibilityIdentifier("shape.\(shape.rawValue)")
                }
            }.padding()
        }
        .navigationTitle("Ring Shapes")
    }

    private func preview(_ snapshot: RingSnapshot, progress: Double) -> RingSnapshot {
        RingSnapshot(progress: progress, mainColor: snapshot.mainColor, gradient: snapshot.gradient,
                     secondaryColor: snapshot.secondaryColor, outerGlow: false)
    }
}
