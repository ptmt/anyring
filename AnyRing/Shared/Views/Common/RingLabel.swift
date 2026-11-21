import SwiftUI

struct RingLabel: View {
    let name: String
    let value: String
    let units: String
    let color: Color
    var body: some View {
        VStack(alignment: .leading) {
            Text(name).font(.footnote)
            Text("\(Text(value).bold()) \(Text(units).font(.footnote))").foregroundStyle(color)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A compact semantic legend; the graphic already represents progress.
struct RingDashboardLegend: View {
    @ObservedObject var ring: RingViewModel
    var showsInformation = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    #if os(iOS)
    @State private var informationPresented = false
    @AccessibilityFocusState private var informationFocused: Bool
    #endif

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            summary.frame(maxWidth: .infinity, alignment: .leading)
            #if os(iOS)
            if showsInformation {
                Button { informationPresented = true } label: {
                    Image(systemName: "info.circle")
                        .font(.body).dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(ring.name) information")
                .accessibilityHint("Shows reading status, source and period")
                .accessibilityIdentifier("metricInfo.\(ring.configuration.ring.rawValue)")
                .accessibilityFocused($informationFocused)
                .sheet(isPresented: $informationPresented, onDismiss: { informationFocused = true }) {
                    RingInformationSheet(ring: ring)
                }
            }
            #endif
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Circle().fill(ring.configuration.appearance.mainColor.color).frame(width: 6, height: 6)
                    .accessibilityHidden(true)
                Text(ring.name).font(.caption).foregroundStyle(.primary)
            }
            if showsInformation && dynamicTypeSize.isAccessibilitySize {
                // Fixed semantic lines keep an unknown value from pulling the
                // target onto a different line during loading/error transitions.
                VStack(alignment: .leading, spacing: 0) {
                    Text(ring.valueText).fontWeight(.semibold).foregroundStyle(.primary)
                    Text("/ \(ring.targetText) \(ring.units)").foregroundStyle(.secondary)
                }.font(.subheadline).monospacedDigit()
            } else {
                // Preserve the compact, shared-unit reading at ordinary sizes.
                Text("\(Text(ring.valueText).fontWeight(.semibold))\(Text(" / \(ring.targetText) \(ring.units)").foregroundColor(.secondary))")
                    .font(.subheadline).monospacedDigit().foregroundStyle(.primary)
            }
            // Noninteractive shared consumers retain their existing diagnostic text.
            if !showsInformation, let error = ring.error {
                Text(error.localizedDescription).font(.caption).foregroundStyle(.secondary)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(ring.name), \(ring.overviewAccessibilityValue)"))
        .accessibilityIdentifier("metric.\(ring.configuration.ring.rawValue)")
    }
}

#if os(iOS)
/// Observes the selected model directly: opening this sheet performs no reads.
private struct RingInformationSheet: View {
    @ObservedObject var ring: RingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Reading") {
                    Text("\(ring.valueText) / \(ring.targetText) \(ring.units)")
                    if ring.isRefreshing { Text("Updating…") }
                    if let error = ring.error { Text(error.localizedDescription) }
                    if let error = ring.error as? HealthDataError, case .noSamples = error {
                        Link("Open Apple Health", destination: URL(string: "x-apple-health://")!)
                    }
                    Text(ring.direction)
                    if let start = ring.startingValueText { Text(start) }
                }
                Section("Source") {
                    Text(ring.fullName)
                    if ring.metricName != ring.name { Text(ring.metricName) }
                    Text(ring.providerDescription).foregroundStyle(.secondary)
                }
                Section("Period") {
                    Text(ring.globalConfig.days == 1 ? "Today" : "Today and the previous \(ring.globalConfig.days - 1) days")
                }
            }
            .navigationTitle(ring.name)
            .navigationBarTitleDisplayMode(.inline)
            #if targetEnvironment(simulator)
            .overlay(alignment: .bottomLeading) {
                if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                   ProcessInfo.processInfo.arguments.contains("--metric-info-fixture"),
                   !ProcessInfo.processInfo.arguments.contains("--metric-info-preview") {
                    HStack {
                        ForEach(["error", "loading", "ready"], id: \.self) { state in
                            Button(state) { ring.setMetricInfoFixture(state) }
                                .accessibilityIdentifier("sheetFixture.\(state)")
                        }
                    }.buttonStyle(.bordered).dynamicTypeSize(.medium).background(.regularMaterial)
                }
            }
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("metricInfoDone")
                }
            }
        }
    }
}
#endif

struct RingMetricView: View {
    @ObservedObject var ring: RingViewModel
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 8) {
            HStack(spacing: 7) {
                Circle().fill(ring.configuration.appearance.mainColor.color).frame(width: 8, height: 8)
                Text(ring.name).font(.subheadline.weight(.medium))
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    value.fixedSize()
                    Spacer(minLength: 12)
                    goal.fixedSize()
                }
                VStack(alignment: .leading, spacing: 4) { value; goal }
            }
            ProgressView(value: min(1, max(0, ring.progress.normalized)))
                .tint(ring.configuration.appearance.mainColor.color)
                .accessibilityHidden(true)
            #if os(iOS)
            if compact {
                Label(ring.direction, systemImage: ring.isReversed ? "arrow.down.right" : "arrow.up.right")
                    .font(.caption2).foregroundStyle(.secondary)
                if let start = ring.startingValueText { Text(start).font(.caption2).foregroundStyle(.secondary) }
            }
            #else
            HStack(alignment: .top, spacing: 8) {
                Label(ring.direction, systemImage: ring.isReversed ? "arrow.down.right" : "arrow.up.right")
                if let start = ring.startingValueText { Spacer(minLength: 4); Text(start) }
            }
            .font(compact ? .caption2 : .caption)
            .foregroundStyle(.secondary)
            #endif
            if let error = ring.error { Text(error.localizedDescription).font(.caption).foregroundStyle(.secondary) }
        }
        .padding(.vertical, compact ? 4 : 6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("metric.\(ring.configuration.ring.rawValue)")
    }

    private var value: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(ring.valueText).font(compact ? .title3.weight(.semibold) : .title2.weight(.semibold))
                .monospacedDigit().contentTransition(.numericText())
            Text(ring.units).font(.subheadline).foregroundStyle(.secondary)
        }
    }
    private var goal: some View {
        HStack(spacing: 4) {
            if ring.progress.normalized >= 1 { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            Text("Goal \(ring.goalText)").font(compact ? .caption : .subheadline).foregroundStyle(.secondary)
        }
    }
}
