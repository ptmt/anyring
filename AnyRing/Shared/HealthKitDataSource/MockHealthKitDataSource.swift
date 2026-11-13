import Foundation
import HealthKit

final class MockHealthKitDataSource: HealthKitDataSource {
    func isAvailable() -> Bool { true }
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool { true }

    func fetchStatistics(withStart: Date, to: Date, ofType sampleType: HKSampleType,
                         unit: HKUnit, aggregation: Aggregation) async throws -> Double {
        try Task.checkCancellation()
        switch sampleType {
        case HKQuantityType(.heartRate): return 55
        case HKQuantityType(.heartRateVariabilitySDNN): return 110
        case HKQuantityType(.appleStandTime): return 8
        case HKQuantityType(.activeEnergyBurned): return 1100
        case HKQuantityType(.appleExerciseTime): return 110
        case HKQuantityType(.stepCount): return 5100
        default: return 0
        }
    }
}
