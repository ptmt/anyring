//
//  RingWidget.swift
//  RingWidget
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import WidgetKit
import SwiftUI


struct Provider: TimelineProvider {
    let viewModel = AnyRingViewModel()
    let cache = SimpleCache()
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                    size: context.displaySize,
                    rings: cache.restoreLastSnapshot() ?? staticSnapshot)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        viewModel.updateProviders()
        viewModel.getSnapshots { snapshots, error in
            cache.store(lastSnapshot: snapshots)
            let entry = SimpleEntry(date: Date(),
                                    size: context.displaySize,
                                    rings: snapshots ?? cache.restoreLastSnapshot(),
                                    error: error)
            completion(entry)
        }
        
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        
        // make sure we invalidate the providers
        viewModel.updateProviders()
        viewModel.getSnapshots { snapshots, error in
            cache.store(lastSnapshot: snapshots)
            let entry = SimpleEntry(date: Date(),
                                    size: context.displaySize,
                                    rings: snapshots ?? cache.restoreLastSnapshot(),
                                    error: error)
            
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let size: CGSize
    var rings: RingWrapper<RingSnapshot>? = nil
    var error: Error? = nil
}


struct RingWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        if let rings = entry.rings {
            let delta: CGFloat = 15
            let size = min(entry.size.width, entry.size.height) - delta
            VStack {
                TripleRingView(size: size - delta,
                               ring1: rings.first,
                               ring2: rings.second,
                               ring3: rings.third)
            }
            .padding(.all, delta)
        } else if let error = entry.error {
            Group {
                Text(error.localizedDescription).font(.body).padding()
            }
        } else {
            Group {
                Text("Loading rings").font(.headline)
            }
        }
        
    }
}

@main
struct RingWidget: Widget {
    let kind: String = "RingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            
            RingWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemLarge])
        .configurationDisplayName("AnyProgress")
        .description("Configure custom progress trackers, using external data providers and make them based on any time interval")
    }
}

let staticSnapshot = RingWrapper([RingSnapshot(progress: 0.4, mainColor: Color.secondary.codable),
                                  RingSnapshot(progress: 1.5, mainColor: Color.secondary.codable),
                                  RingSnapshot(progress: 0.5, mainColor: Color.secondary.codable)])

struct RingWidget_Previews: PreviewProvider {
    
    
    static var previews: some View {
        Group {
            RingWidgetEntryView(entry: SimpleEntry(date: Date(), size: .init(width: 150, height: 150), rings: staticSnapshot))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            //            RingWidgetEntryView(entry: SimpleEntry(date: Date(), size:
            //                                                   .init(width: 50, height: 50)))
            //                .previewContext(WidgetPreviewContext(family: .systemLarge))
            //            RingWidgetEntryView(entry: SimpleEntry(date: Date(), size: .init(width: 50, height: 50)))
            //                .previewContext(WidgetPreviewContext(family: .systemMedium)).preferredColorScheme(.dark)
        }
        
    }
}
