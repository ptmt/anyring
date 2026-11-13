import Foundation
import HealthKit
import Combine

/// Immutable bridge for Combine promises and Objective-C completion handlers.
/// These APIs deliver on arbitrary queues; the closure must arrange any actor-bound work itself.
final class SendableCallback<Value>: @unchecked Sendable {
    private let callback: (Value) -> Void
    init(_ callback: @escaping (Value) -> Void) { self.callback = callback }
    func call(_ value: Value) { callback(value) }
}

@MainActor
final class DeviceHealthKitDataSource: HealthKitDataSource {
    let healthStore = HKHealthStore()
    private let requireSamples: Bool

    init(requireSamples: Bool = false) { self.requireSamples = requireSamples }
    private var observerQueries: [HKObserverQuery] = []

    func isAvailable() -> Bool { HKHealthStore.isHealthDataAvailable() }

    func requestPermissions(permissions: Set<HKObjectType>) -> Future<Bool, Error> {
        // Read authorization is intentionally private; authorizationStatus is for writing only.
        Future { promise in
            guard Bundle.main.bundleURL.pathExtension != "appex" else { promise(.success(true)); return }
            let callback = SendableCallback(promise)
            self.healthStore.requestAuthorization(toShare: [], read: permissions) { success, error in
                if let error { callback.call(.failure(error)) }
                else { callback.call(.success(success)) }
            }
        }
    }

    nonisolated static func statisticsOption(for aggregation: Aggregation) -> HKStatisticsOptions {
        switch aggregation {
        case .sum: .cumulativeSum
        case .avg: .discreteAverage
        case .min: .discreteMin
        case .max: .discreteMax
        }
    }

    func fetchStatistics(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType,
                         unit: HKUnit, aggregation: Aggregation) -> Future<Double, Error> {
        Future { promise in
            guard let quantityType = sampleType as? HKQuantityType else {
                promise(.failure(HealthDataError.unsupportedType)); return
            }
            let cumulative = quantityType.aggregationStyle == .cumulative
            guard cumulative == (aggregation == .sum) else {
                promise(.failure(HealthDataError.unsupportedAggregation)); return
            }
            let callback = SendableCallback(promise)
            let requireSamples = self.requireSamples
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: quantityType, quantitySamplePredicate: predicate,
                                          options: Self.statisticsOption(for: aggregation)) { _, result, error in
                if let error { callback.call(.failure(error)); return }
                let quantity: HKQuantity?
                switch aggregation {
                case .sum: quantity = result?.sumQuantity()
                case .avg: quantity = result?.averageQuantity()
                case .min: quantity = result?.minimumQuantity()
                case .max: quantity = result?.maximumQuantity()
                }
                do { callback.call(.success(try Self.quantityValue(quantity, unit: unit, requireSamples: requireSamples))) }
                catch { callback.call(.failure(error)) }
            }
            self.healthStore.execute(query)
        }
    }

    nonisolated static func quantityValue(_ quantity: HKQuantity?, unit: HKUnit, requireSamples: Bool = false) throws -> Double {
        guard let quantity else {
            if requireSamples { throw HealthDataError.noSamples }
            return 0
        }
        guard quantity.is(compatibleWith: unit) else { throw HealthDataError.incompatibleUnit }
        return quantity.doubleValue(for: unit)
    }

    func observe(types: Set<HKSampleType>, onChange: @escaping @Sendable () -> Void) {
        observerQueries.forEach { healthStore.stop($0) }
        observerQueries = types.map { type in
            HKObserverQuery(sampleType: type, predicate: nil) { _, completion, error in
                if error == nil { onChange() }
                completion()
            }
        }
        observerQueries.forEach { healthStore.execute($0) }
    }
}

enum HealthDataError: LocalizedError {
    case unsupportedType, unsupportedAggregation, incompatibleUnit, noSamples
    var errorDescription: String? {
        switch self {
        case .noSamples: "No readable health samples. Open AnyProgress to check Health access."
        case .incompatibleUnit: "The unit does not match the selected health metric."
        case .unsupportedType: "This health data type does not support statistics."
        case .unsupportedAggregation: "This aggregation is unavailable for the selected health data. Choose Sum for cumulative data, or Average, Minimum, or Maximum for discrete data."
        }
    }
}
