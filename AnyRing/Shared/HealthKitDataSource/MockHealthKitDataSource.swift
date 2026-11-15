import Foundation
import HealthKit

final class MockHealthKitDataSource: HealthKitDataSource {
    #if targetEnvironment(simulator)
    private(set) var readCount = 0
    #endif
    func isAvailable() -> Bool { true }
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool { true }

    func fetchWorkouts(from start: Date, to end: Date) async throws -> [WorkoutZoneRecord] {
        try Task.checkCancellation()
        #if targetEnvironment(simulator)
        guard ProcessInfo.processInfo.arguments.contains("--workout-zone-fixture") else { throw WorkoutZoneError.noReadableZones }
        readCount += 1
        let finish = end.addingTimeInterval(-60)
        return [WorkoutZoneRecord(id: "simulator-synthetic-workout", start: finish.addingTimeInterval(-600),
            end: finish, activeDuration: 600, configurationIndices: Array(0...4),
            durations: [0: 60, 1: 120, 2: 180, 3: 60, 4: 180])]
        #else
        throw WorkoutZoneError.noReadableZones
        #endif
    }

    func fetchStatistics(withStart: Date, to: Date, ofType sampleType: HKSampleType,
                         unit: HKUnit, aggregation: Aggregation) async throws -> Double {
        try Task.checkCancellation()
        #if targetEnvironment(simulator)
        readCount += 1
        #endif
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
