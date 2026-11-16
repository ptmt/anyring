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
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Circle().fill(ring.configuration.appearance.mainColor.color).frame(width: 6, height: 6)
                    .accessibilityHidden(true)
                Text(ring.name).font(.caption).foregroundStyle(.primary)
            }
            Text("\(Text(ring.valueText).fontWeight(.semibold)) \(ring.units)")
                .font(.subheadline).monospacedDigit()
                .foregroundStyle(.primary)
            Text("Goal \(ring.goalText)").font(.caption2).foregroundStyle(.secondary)
            if let start = ring.startingValueText { Text(start).font(.caption2).foregroundStyle(.secondary) }
            if let error = ring.error { Text(error.localizedDescription).font(.caption).foregroundStyle(.secondary) }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("metric.\(ring.configuration.ring.rawValue)")
    }
}

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
