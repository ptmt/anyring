import WidgetKit
import SwiftUI
#if WIDGET_TESTING
@testable import AnyProgress
#endif

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), rings: nil, names: [], readingDate: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        load(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let callback = SendableCallback(completion)
        load { entry in
            callback.call(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(1800))))
        }
    }

    private func load(completion: @escaping (SimpleEntry) -> Void) {
        let callback = SendableCallback(completion)
        Task { @MainActor in
            let persistence = UserDefaultsConfigurationPersistence()
            guard let config = persistence.restore() else {
                callback.call(SimpleEntry(date: Date(), rings: nil, names: [], readingDate: nil))
                return
            }
            // Real HealthKit also on Simulator; fixtures belong only in previews/tests.
            let model = AnyRingViewModel(persistence: persistence, dataSource: DeviceHealthKitDataSource(requireSamples: true), requestAuthorization: false)
            let cache = persistence.widgetCache
            model.getSnapshots { [model] snapshots, _ in
                _ = model // Keep the providers alive until HealthKit completes.
                guard persistence.restore() == config else {
                    callback.call(SimpleEntry(date: Date(), rings: nil, names: [], readingDate: nil))
                    return
                }
                cache.store(lastSnapshot: snapshots, config: config)
                let reading = cache.restoreReading(config: config)
                callback.call(SimpleEntry(date: Date(), rings: reading.map { RingWrapper($0.rings) },
                                          names: config.configs.map(\.name), readingDate: reading?.date))
            }
        }
    }
}

struct SimpleEntry: TimelineEntry, Sendable {
    let date: Date
    var rings: RingWrapper<RingSnapshot>?
    let names: [String]
    let readingDate: Date?
}

struct RingWidgetEntryView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) private var environmentFamily
    @Environment(\.redactionReasons) private var redactionReasons
    var familyOverride: WidgetFamily? = nil
    private var family: WidgetFamily { familyOverride ?? environmentFamily }

    var body: some View {
        Group {
            if redactionReasons.contains(.privacy) {
                Image(systemName: "circle.circle").accessibilityLabel("AnyProgress")
            } else if let rings = entry.rings {
                switch family {
                case .accessoryInline:
                    Text("\(entry.names.first ?? "Progress") \(rings.first.percentageText)")
                case .accessoryRectangular:
                    HStack(spacing: 6) {
                        ringGraphic(rings, size: 44)
                        VStack(alignment: .leading, spacing: 1) {
                            ForEach(0..<3, id: \.self) { index in
                                Text("\(name(at: index)) \(rings.list[index].percentageText)")
                                    .lineLimit(1).minimumScaleFactor(0.8)
                                    .font(.caption2)
                            }
                        }
                    }
                default:
                    GeometryReader { geometry in
                        let size = max(20, min(geometry.size.width, geometry.size.height) - 4)
                        ringGraphic(rings, size: size)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                if family == .accessoryCircular {
                    Image(systemName: "circle.circle").font(.title2)
                } else {
                    Text("Open AnyProgress").font(.caption).lineLimit(2)
                }
            }
        }
        .containerBackground(.background, for: .widget)
        .privacySensitive()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        #if os(iOS)
        .widgetURL(entry.rings != nil && family == .accessoryInline
                   ? WidgetDestination.ring(.first).url : WidgetDestination.overview.url)
        #endif
    }

    private func name(at index: Int) -> String {
        entry.names.indices.contains(index) ? entry.names[index] : "Progress"
    }

    private var accessibilitySummary: String {
        guard !redactionReasons.contains(.privacy) else { return "AnyProgress" }
        guard let rings = entry.rings else { return "Open AnyProgress to load your rings" }
        let indices = family == .accessoryInline ? [0] : [0, 1, 2]
        var summary = indices.map { "\(name(at: $0)): \(rings.list[$0].percentageText)" }.joined(separator: ", ")
        if let date = entry.readingDate { summary += ". Updated \(date.formatted(date: .abbreviated, time: .shortened))" }
        return summary
    }

    private func ringGraphic(_ rings: RingWrapper<RingSnapshot>, size: CGFloat) -> some View {
        TripleRingView(size: size, ring1: rings.first, ring2: rings.second, ring3: rings.third,
                       simplified: true, shape: family == .accessoryCircular ? .circle : .rectangular)
            .widgetAccentable()
    }
}

#if !WIDGET_TESTING
@main
#endif
struct RingWidget: Widget {
    let kind = "RingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in RingWidgetEntryView(entry: entry) }
            .configurationDisplayName("AnyProgress")
            .description("Your rings and goals from AnyProgress. The inline widget shows your first ring.")
            #if os(watchOS)
            .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
            #else
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
            #endif
    }
}

#if DEBUG && !WIDGET_TESTING
private let previewEntry = SimpleEntry(date: Date(), rings: RingWrapper([
    RingSnapshot(progress: 0, mainColor: CodableColor(.green)),
    RingSnapshot(progress: 0.5, mainColor: CodableColor(.pink)),
    RingSnapshot(progress: 1.5, mainColor: CodableColor(.yellow))
]), names: ["Recovery", "Steps", "Energy"], readingDate: Date())

#Preview(as: .accessoryCircular) { RingWidget() } timeline: { previewEntry }
#Preview(as: .accessoryRectangular) { RingWidget() } timeline: { previewEntry }
#Preview(as: .accessoryInline) { RingWidget() } timeline: { previewEntry }
#Preview("No saved rings", as: .accessoryRectangular) { RingWidget() } timeline: {
    SimpleEntry(date: Date(), rings: nil, names: [], readingDate: nil)
}
#endif
