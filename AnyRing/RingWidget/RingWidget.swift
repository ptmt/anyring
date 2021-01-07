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
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(),
                    size: context.displaySize,
                    rings: staticSnapshot)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        viewModel.updateProviders()
        viewModel.getSnapshots { snapshots, _ in
            let entry = SimpleEntry(date: Date(),
                                    size: context.displaySize,
                                    rings: snapshots ?? staticSnapshot)
            completion(entry)
        }
        
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 10, to: Date())!
        
        // make sure we invalidate the providers
        viewModel.updateProviders()
        viewModel.getSnapshots { snapshots, _ in
            let entry = SimpleEntry(date: Date(),
                                    size: context.displaySize,
                                    rings: snapshots ?? staticSnapshot)
            
            let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let size: CGSize
    var rings: RingWrapper<RingSnapshot>//? = nil
}


struct RingWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
       // if let rings = entry.rings {
//            ZStack {
//                Text("\(entry.rings.first.progress)")
//                Text("\(entry.rings.second.progress)")
//                Text("\(entry.rings.third.progress)")
//            }
//        } else {
//            Group {
//                Text("Loading rings").font(.headline)
//            }
//        }
//        if let rings = entry.rings {
            let delta: CGFloat = 15
            let size = min(entry.size.width, entry.size.height) - delta
            VStack {
                TripleRingView(size: size - delta,
                               ring1: entry.rings.first,
                               ring2: entry.rings.second,
                               ring3: entry.rings.third)
            }
            .padding(.all, delta)
//        } else {
//            Group {
//                Text("Loading rings").font(.headline)
//            }
//        }
        
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

let staticSnapshot = RingWrapper([RingSnapshot(progress: 0.4, mainColor: Color.secondary),
                                  RingSnapshot(progress: 1.5, mainColor: Color.secondary),
                                  RingSnapshot(progress: 0.5, mainColor: Color.secondary)])

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
