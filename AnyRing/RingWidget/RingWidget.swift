import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), rings: staticSnapshot, names: ["HRV", "Steps", "Energy"])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        if context.isPreview { completion(placeholder(in: context)); return }
        load(completion: completion)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let callback = SendableCallback(completion)
        load { entry in
            callback.call(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(600))))
        }
    }

    private func load(completion: @escaping (SimpleEntry) -> Void) {
        let callback = SendableCallback(completion)
        Task { @MainActor in
            // A fresh model per request reads current shared storage and never prompts for permission.
            let model = AnyRingViewModel(requestAuthorization: false)
            let config = model.config
            let cache = SimpleCache()
            model.getSnapshots { [model] snapshots, _ in
                _ = model // Keep the providers alive until HealthKit completes.
                cache.store(lastSnapshot: snapshots, config: config)
                callback.call(SimpleEntry(date: Date(), rings: snapshots ?? cache.restoreLastSnapshot(config: config),
                                          names: config.configs.map(\.name)))
            }
        }
    }
}

struct SimpleEntry: TimelineEntry, Sendable {
    let date: Date
    var rings: RingWrapper<RingSnapshot>?
    let names: [String]
}

struct RingWidgetEntryView: View {
    let entry: SimpleEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if let rings = entry.rings {
                switch family {
                case .accessoryInline:
                    Text("\(entry.names.first ?? "Progress") \(Int(min(999, max(0, rings.first.progress * 100))))%")
                case .accessoryRectangular:
                    HStack {
                        ringGraphic(rings, size: 50)
                        VStack(alignment: .leading) {
                            ForEach(Array(entry.names.enumerated()), id: \.offset) { index, name in
                                Text("\(name) \(Int(min(999, max(0, rings.list[index].progress * 100))))%")
                                    .font(.caption2)
                            }
                        }
                    }
                default:
                    GeometryReader { geometry in
                        let size = max(20, min(geometry.size.width, geometry.size.height))
                        ringGraphic(rings, size: size)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            } else {
                Text("Open AnyProgress to load health data").font(.caption)
            }
        }
        .containerBackground(.background, for: .widget)
        .privacySensitive()
    }

    private func ringGraphic(_ rings: RingWrapper<RingSnapshot>, size: CGFloat) -> some View {
        TripleRingView(size: size, ring1: rings.first, ring2: rings.second, ring3: rings.third,
                       simplified: true, shape: family == .accessoryCircular ? .circle : .rectangular)
            .accessibilityLabel("Your three progress rings")
            .widgetAccentable()
    }
}

@main
struct RingWidget: Widget {
    let kind = "RingWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in RingWidgetEntryView(entry: entry) }
            .configurationDisplayName("AnyProgress")
            .description("Your custom Apple Health progress rings.")
            #if os(watchOS)
            .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
            #else
            .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline])
            #endif
    }
}

let staticSnapshot = RingWrapper([
    RingSnapshot(progress: 0.7, mainColor: CodableColor(.green)),
    RingSnapshot(progress: 0.5, mainColor: CodableColor(.pink)),
    RingSnapshot(progress: 0.9, mainColor: CodableColor(.yellow))
])
