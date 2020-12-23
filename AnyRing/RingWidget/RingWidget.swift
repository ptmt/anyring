//
//  RingWidget.swift
//  RingWidget
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                    size: context.displaySize,
                    rings: staticSnapshot)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        AnyRingViewModel().getSnapshots { snapshots in
            let entry = SimpleEntry(date: Date(),
                                    size: context.displaySize,
                                    rings: snapshots)
            completion(entry)
        }
       
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let refreshDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        AnyRingViewModel().getSnapshots { snapshots in
            let entry = SimpleEntry(date: Date(),
                                    size: context.displaySize,
                                    rings: snapshots)
            
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let size: CGSize
    var rings: RingWrapper<RingSnapshot>? = nil
}


struct RingWidgetEntryView : View {
    var entry: Provider.Entry
   
    
    var body: some View {
        if let rings = entry.rings {
                let size = min(entry.size.width, entry.size.height) - 20
            VStack {
                Text("\(rings.first.progress) \(rings.second.progress)")
                TripleRingView(size: size - 20,
                               ring1: rings.first,
                               ring2: rings.second,
                               ring3: rings.third)
            }
                    .padding(.all, 10)
            } else {
                Text("Loading rings")
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
        .configurationDisplayName("AnyRing")
        .description("Configure custom rings, using external data providers and based on any time interval")
    }
}

let staticSnapshot = RingWrapper([RingSnapshot(progress: 0.7, color: Color.green),
                                         RingSnapshot(progress: 1.5, color: Color.yellow),
                                         RingSnapshot(progress: 0.3, color: Color.red)])

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