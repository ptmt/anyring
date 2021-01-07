//
//  ComplicationController.swift
//  AnyRingWatch Extension
//
//  Created by Dmitriy Loktev on 18.12.2020.
//

import ClockKit
import SwiftUI

class ComplicationController: NSObject, CLKComplicationDataSource {
    let viewModel = AnyRingViewModel()
    
    // MARK: - Complication Configuration
    
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "AnyRing", supportedFamilies: [.graphicCircular, .modularSmall])
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }
    
    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        handler(nil)
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.hideOnLockScreen)
    }
    
    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // Call the handler with the current timeline entry
        precondition(Thread.isMainThread)
        // make sure we invalide providers since the config can
        // be changed
        viewModel.updateProviders()
        viewModel.getSnapshots { (currentSnapshot, error) in
            if let snapshot = currentSnapshot {
                let entry = self.createTimelineEntry(forComplication: complication, date: Date(), snapshot: snapshot)
                handler(entry)
            } else {
                handler(nil)
            }
        }
    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        // Call the handler with the timeline entries after the given date
        handler(nil)
    }
    
    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    // Return a timeline entry for the specified complication and date.
    private func createTimelineEntry(forComplication complication: CLKComplication, date: Date, snapshot: RingWrapper<RingSnapshot>) -> CLKComplicationTimelineEntry {
        
        // Get the correct template based on the complication.
        let template = createTemplate(forComplication: complication, date: date, snapshot: snapshot)
        
        // Use the template and date to create a timeline entry.
        return CLKComplicationTimelineEntry(date: date, complicationTemplate: template)
    }
    
    private func createTemplate(forComplication complication: CLKComplication, date: Date, snapshot: RingWrapper<RingSnapshot>) -> CLKComplicationTemplate {
        switch complication.family {
        case .modularSmall:
            return createCircularSmallTemplate(forDate: date, snapshot: snapshot)
        case .graphicCircular:
            return createCircularSmallTemplate(forDate: date, snapshot: snapshot)
        default:
            fatalError("*** \(complication.family) Not supported ***")
        //        @unknown default:
        //            fatalError("*** Unknown Complication Family ***")
        }
    }
    
    func createModularSmallTemplate(forDate date: Date, snapshot: RingWrapper<RingSnapshot>) -> CLKComplicationTemplate {
        // Create the data providers.
        let mgCaffeineProvider = CLKSimpleTextProvider(text: "123")
        let mgUnitProvider = CLKSimpleTextProvider(text: "mg Caffeine", shortText: "mg")
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateModularSmallStackText(line1TextProvider: mgCaffeineProvider, line2TextProvider: mgUnitProvider)
        return template
    }
    
    func createCircularSmallTemplate(forDate date: Date, snapshot: RingWrapper<RingSnapshot>) -> CLKComplicationTemplate {
        
        // Create the template using the providers.
        let template = CLKComplicationTemplateGraphicCircularView(ComplicationView(snapshot: snapshot))
        
        return template
    }
}

let staticSnapshot = RingWrapper([RingSnapshot(progress: 0.4, mainColor: CodableColor(Color.pink)),
                                  RingSnapshot(progress: 1.5, mainColor: CodableColor(Color.orange)),
                                  RingSnapshot(progress: 0.1, mainColor: CodableColor(Color.blue))])


struct ComplicationView: View {
    
    var snapshot: RingWrapper<RingSnapshot>
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            TripleRingView(size: size,
                           ring1: snapshot.first,
                           ring2: snapshot.second,
                           ring3: snapshot.third)
            
        }
    }
}

struct ComplicationController_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            ComplicationController().createCircularSmallTemplate(forDate: Date(), snapshot: staticSnapshot).previewContext()
        }
    }
}
