//
//  HealthKitDataSource.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import HealthKit


@MainActor
protocol HealthKitDataSource {
    func isAvailable() -> Bool
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [WorkoutZoneRecord]
    func fetchStatistics(withStart startDate: Date, to endDate: Date, ofType sampleType: HKSampleType, unit: HKUnit, aggregation: Aggregation) async throws -> Double
}

extension HealthKitDataSource {
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [WorkoutZoneRecord] {
        throw WorkoutZoneError.unavailable
    }
}

enum WorkoutZoneMetric: String, Codable, CaseIterable, Sendable {
    case combinedZones2And3, combinedZones4And5
    var name: String {
        switch self {
        case .combinedZones2And3: "Heart rate zones 2–3"
        case .combinedZones4And5: "Heart rate zones 4–5"
        }
    }
    var indices: Set<Int> {
        switch self {
        case .combinedZones2And3: [1, 2]
        case .combinedZones4And5: [3, 4]
        }
    }
}

/// Only parent workout aggregates; never add the parent and its activities.
struct WorkoutZoneRecord: Sendable {
    let id: String
    let start: Date
    let end: Date
    let activeDuration: TimeInterval
    let configurationIndices: [Int]
    let durations: [Int: TimeInterval]?
}

enum WorkoutZoneError: LocalizedError {
    case unavailable, noReadableZones, incompleteCoverage
    var errorDescription: String? {
        switch self {
        case .unavailable: "Workout zones require iOS 27 or watchOS 27."
        case .noReadableZones: "No readable workout zones. Check Workouts and Heart Rate access."
        case .incompleteCoverage: "Incomplete workout zones: missing data, overlapping workouts or a period boundary."
        }
    }
}

enum WorkoutZoneTotals {
    static func period(days: Int, now: Date, calendar: Calendar = .current) -> DateInterval {
        let first = calendar.date(byAdding: .day, value: -(max(days, 1) - 1), to: now) ?? now
        return DateInterval(start: calendar.startOfDay(for: first), end: now)
    }

    static func minutes(_ metric: WorkoutZoneMetric, records: [WorkoutZoneRecord], period: DateInterval) throws -> Double {
        var seen = Set<String>()
        let relevant = records.sorted {
            if $0.start != $1.start { return $0.start < $1.start }
            return $0.id < $1.id
        }.filter { $0.end > period.start && $0.start < period.end && seen.insert($0.id).inserted }
        guard !relevant.isEmpty else { throw WorkoutZoneError.noReadableZones }
        var lastEnd: Date?
        var seconds = 0.0
        for record in relevant {
            guard record.start >= period.start, record.end <= period.end,
                  record.end > record.start,
                  lastEnd.map({ record.start >= $0 }) ?? true,
                  record.activeDuration.isFinite, record.activeDuration > 0,
                  record.activeDuration <= record.end.timeIntervalSince(record.start) + 1,
                  record.configurationIndices == Array(0...4),
                  let durations = record.durations,
                  Set(durations.keys) == Set(0...4),
                  durations.values.allSatisfy({ $0.isFinite && $0 >= 0 }),
                  durations.values.reduce(0, +) > 0,
                  // Stored HealthKit aggregates are authoritative, not a reconstructed
                  // sampling timeline. Missing wall/active coverage is not an API error.
                  durations.values.reduce(0, +) <= record.end.timeIntervalSince(record.start) + 1 else {
                throw WorkoutZoneError.incompleteCoverage
            }
            lastEnd = record.end
            seconds += metric.indices.reduce(0) { $0 + (durations[$1] ?? 0) }
        }
        return seconds / 60
    }
}
