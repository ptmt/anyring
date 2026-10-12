import ClockKit

/// Retained only to migrate complications already installed on a user's watch face.
@available(watchOS, deprecated: 10.0, message: "Migration bridge for installed ClockKit complications")
final class ComplicationController: NSObject, CLKComplicationDataSource, CLKComplicationWidgetMigrator {
    var widgetMigrator: any CLKComplicationWidgetMigrator { self }

    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        handler([CLKComplicationDescriptor(identifier: "complication", displayName: "AnyProgress",
                                            supportedFamilies: [.graphicCircular, .modularSmall])])
    }

    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        handler(nil)
    }

    nonisolated func widgetConfiguration(from complicationDescriptor: CLKComplicationDescriptor) async -> CLKComplicationWidgetMigrationConfiguration? {
        guard complicationDescriptor.identifier == "complication" || complicationDescriptor.identifier == CLKDefaultComplicationIdentifier else { return nil }
        return CLKComplicationStaticWidgetMigrationConfiguration(kind: "RingWidget",
                           extensionBundleIdentifier: "com.potomushto.AnyRing.watchkitapp.RingWidget")
    }
}
