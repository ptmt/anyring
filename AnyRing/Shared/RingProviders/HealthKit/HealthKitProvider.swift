//
//  ActivityProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation
import HealthKit


//let activityMinutesConfiguration = HealthKitProvider.HealthKitConfiguration(
//    name: "Activity Minutes",
//    description: "A quantity sample type that measures the amount of time the user spent exercising.",
//    units: HKUnitCodable.minute,
//    sampleType: HKObjectTypeCodable.appleExerciseTime,
//    minValue: 0,
//    maxValue: 200,
//    aggregation: .sum)

let hrvConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "HRV",
    description: "A quantity sample type that measures the standard deviation of heartbeat intervals.",
    units: HKUnitCodable.millisecond,
    sampleType: HKObjectTypeCodable.heartRateVariabilitySDNN,
    minValue: 0,
    maxValue: 100,
    aggregation: .max)

let hrConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Heart-rate",
    description: "A quantity sample type that measures the user’s heart rate.",
    units: HKUnitCodable.countperminute,
    sampleType: HKObjectTypeCodable.heartRate,
    minValue: 30,
    maxValue: 200,
    reversed: true,
    aggregation: .min)

let bloodAlcoholContentConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Blood Alchohol %",
    description: "A quantity sample type that measures the user’s blood alcohol content.",
    units: HKUnitCodable.percent,
    sampleType: HKObjectTypeCodable.bloodAlcoholContent,
    minValue: 0,
    maxValue: 100,
    aggregation: .max)

let dietaryCaffeineConfiguration = HealthKitProvider.HealthKitConfiguration(
    name: "Caffeine",
    description: "A quantity sample type that measures the amount of caffeine consumed.",
    units: HKUnitCodable.mgrams,
    sampleType: HKObjectTypeCodable.dietaryCaffeine,
    minValue: 0,
    maxValue: 100,
    aggregation: .sum)

//let appleStandTime = HealthKitProvider.HealthKitConfiguration(
//    name: "Standing hours",
//    description: "A quantity sample type that measures the amount of time the user has spent standing.",
//    units: HKUnitCodable.minute,
//    sampleType: HKObjectTypeCodable.appleStandTime,
//    minValue: 0,
//    maxValue: 100,
//    aggregation: .sum)

let pushCount = HealthKitProvider.HealthKitConfiguration(
    name: "Pushes",
    description: "A quantity sample type that measures the number of pushes that the user has performed while using a wheelchair.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.pushCount,
    minValue: 0,
    maxValue: 400,
    aggregation: .sum)

let stepCount = HealthKitProvider.HealthKitConfiguration(
    name: "Step count",
    description: "The number of steps recorded in Apple Health.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.stepCount,
    minValue: 0,
    maxValue: 8000,
    aggregation: .sum)

//let distanceWalkingRunning = HealthKitProvider.HealthKitConfiguration(
//    name: "Distance",
//    description: "A quantity sample type that measures the distance the user has moved by walking or running.",
//    units: HKUnitCodable.meter,
//    sampleType: HKObjectTypeCodable.distanceWalkingRunning,
//    minValue: 0,
//    maxValue: 10000,
//    aggregation: .sum)

let distanceSwimming = HealthKitProvider.HealthKitConfiguration(
    name: "Swim",
    description: "The distance you have swum, recorded in Apple Health.",
    units: HKUnitCodable.meter,
    sampleType: HKObjectTypeCodable.distanceSwimming,
    minValue: 0,
    maxValue: 2000,
    aggregation: .sum)

let flightsClimbed = HealthKitProvider.HealthKitConfiguration(
    name: "Flights Climbed",
    description: "A quantity sample type that measures the number flights of stairs that the user has climbed.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.flightsClimbed,
    minValue: 0,
    maxValue: 2000,
    aggregation: .sum)

let nikeFuel = HealthKitProvider.HealthKitConfiguration(
    name: "Nike Fuel",
    description: "A quantity sample type that measures the number of NikeFuel points the user has earned.",
    units: HKUnitCodable.count,
    sampleType: HKObjectTypeCodable.nikeFuel,
    minValue: 0,
    maxValue: 2000,
    aggregation: .sum)

let vo2Max = HealthKitProvider.HealthKitConfiguration(
    name: "VO2Max",
    description: "A quantity sample that measures the maximal oxygen consumption during incremental exercise.",
    units: HKUnitCodable.oxygenUptake,
    sampleType: HKObjectTypeCodable.vo2Max,
    minValue: 0,
    maxValue: 100,
    aggregation: .avg)

let activeEnergyBurned = HealthKitProvider.HealthKitConfiguration(
    name: "Active Energy",
    description: "A quantity sample type that measures the amount of active energy the user has burned.",
    units: HKUnitCodable.kilocalorie,
    sampleType: HKObjectTypeCodable.activeEnergyBurned,
    minValue: 0,
    maxValue: 1500,
    aggregation: .sum)

let distanceCycling = HealthKitProvider.HealthKitConfiguration(
    name: "Cycling",
    description: "A quantity sample type that measures the distance the user has moved by cycling.",
    units: HKUnitCodable.meter,
    sampleType: HKObjectTypeCodable.distanceCycling,
    minValue: 0,
    maxValue: 10000,
    aggregation: .sum)

let healthKitProviders = [
    stepCount,
    pushCount,
    distanceSwimming,
    flightsClimbed,
    nikeFuel,
    vo2Max,
    activeEnergyBurned,
    distanceCycling,
    hrvConfiguration,
    hrConfiguration,
    bloodAlcoholContentConfiguration,
    dietaryCaffeineConfiguration,
] + dietProviders

enum Aggregation: String, Codable, Sendable {
    case avg = "Avg"
    case sum = "Sum"
    case min = "Min"
    case max = "Max"
}

class HealthKitProvider: RingProvider {
    
    struct HealthKitConfiguration: Codable, Hashable, Sendable {
        var name: String
        var description: String
        var units: HKUnitCodable
        var sampleType: HKObjectTypeCodable
        var minValue: Double = 0
        var maxValue: Double = 200
        var reversed: Bool = false
        var aggregation: Aggregation = Aggregation.max
    }
    
    struct Configuration: ProviderConfiguration {
        var provider: RingProvider.Type { workoutMetric == nil ? HealthKitProvider.self : HealthKitWorkoutProvider.self }
        var workoutMetric: WorkoutZoneMetric? = nil
        var ring: RingID
        var healthKitParams: HealthKitConfiguration
        var appearance: RingAppearance
        var customName: String? = nil {
            didSet { customName = RingName.normalized(customName) }
        }

        enum CodingKeys: String, CodingKey { case ring, healthKitParams, appearance, customName, workoutMetric }

        init(ring: RingID, healthKitParams: HealthKitConfiguration, appearance: RingAppearance, customName: String? = nil) {
            self.ring = ring
            self.healthKitParams = healthKitParams
            self.appearance = appearance
            self.customName = RingName.normalized(customName)
        }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            workoutMetric = try values.decodeIfPresent(WorkoutZoneMetric.self, forKey: .workoutMetric)
            ring = try values.decode(RingID.self, forKey: .ring)
            healthKitParams = try values.decode(HealthKitConfiguration.self, forKey: .healthKitParams)
            appearance = try values.decode(RingAppearance.self, forKey: .appearance)
            customName = RingName.normalized(try values.decodeIfPresent(String.self, forKey: .customName))
        }
        
        var minValue: Double {
            get {
                healthKitParams.minValue
            }
            set {
                healthKitParams.minValue = newValue
            }
        }
        
        var maxValue: Double {
            get {
                healthKitParams.maxValue
            }
            set {
                healthKitParams.maxValue = newValue
            }
        }
        
        var name: String {
            get {
                workoutMetric?.name ?? healthKitParams.name
            }
            set {
                healthKitParams.name = newValue
            }
        }
        
        var readTypes: Set<HKSampleType> {
            workoutMetric == nil ? [healthKitParams.sampleType.hkSampleType] : [HKObjectType.workoutType(), HKQuantityType(.heartRate)]
        }

        mutating func selectWorkoutMetric(_ metric: WorkoutZoneMetric) {
            workoutMetric = metric
            // Compatibility payload for older builds: unsupported aggregation fails closed,
            // rather than displaying an unrelated heart-rate mean as workout minutes.
            healthKitParams = HealthKitConfiguration(name: metric.name,
                description: "Stored heart rate zones during workouts only.", units: .minute,
                sampleType: .heartRate, minValue: 0, maxValue: 30, aggregation: .sum)
        }

        var units: String {
            workoutMetric == nil ? healthKitParams.units.displaySymbol(for: healthKitParams.sampleType) : "min"
        }
    }
    
    static let configurationType: ProviderConfiguration.Type = Configuration.self
    
    static let name = "Apple Health"
    static let description = """
    Some data sources are available only if you're using Apple Watch.
    """
    
    private let dataSource: HealthKitDataSource
    
    var config: ProviderConfiguration
    let configPersistence: ConfigurationPersistence
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration, configPersistence: ConfigurationPersistence) {
        self.dataSource = dataSource
        self.config = config as! Configuration
        self.configPersistence = configPersistence
    }
    
    
    func calculateProgress(providerConfig: ProviderConfiguration, globalConfig: GlobalConfiguration) async throws -> Progress {
        try Task.checkCancellation()
        let configuration = providerConfig as! Configuration
        if let metric = configuration.workoutMetric {
            return try await HealthKitWorkoutProvider.progress(metric: metric, configuration: configuration,
                global: globalConfig, dataSource: dataSource)
        }
        let parameters = configuration.healthKitParams
        let calendar = Calendar.current
        let now = Date()
        let firstDay = calendar.date(byAdding: .day, value: -(max(globalConfig.days, 1) - 1), to: now) ?? now
        let value = try await dataSource.fetchStatistics(
            withStart: calendar.startOfDay(for: firstDay), to: now,
            ofType: parameters.sampleType.hkSampleType, unit: parameters.units.hkunit,
            aggregation: parameters.aggregation)
        // Await resumes on MainActor even when HealthKit completes on a background queue.
        try Task.checkCancellation()
        return Progress(absolute: value, maxAbsolute: providerConfig.maxValue,
                        minAbsolute: providerConfig.minValue, reversed: parameters.reversed)
    }

    func viewModel(globalConfig: GlobalConfiguration) -> RingViewModel {
        RingViewModel(provider: self, globalConfig: globalConfig)
    }
}


/// Dedicated workout source; existing configuration/cache/Watch transport remains shared.
final class HealthKitWorkoutProvider: HealthKitProvider {
    static func progress(metric: WorkoutZoneMetric, configuration: Configuration,
                         global: GlobalConfiguration, dataSource: any HealthKitDataSource) async throws -> Progress {
        try Task.checkCancellation()
        let period = WorkoutZoneTotals.period(days: global.days, now: Date())
        let records = try await dataSource.fetchWorkouts(from: period.start, to: period.end)
        try Task.checkCancellation()
        let minutes = try WorkoutZoneTotals.minutes(metric, records: records, period: period)
        return Progress(absolute: minutes, maxAbsolute: configuration.maxValue,
                        minAbsolute: 0, reversed: false)
    }
}

let secondsInDayApprox: Double = 60 * 60 * 24

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}


extension HealthKitProvider.Configuration {
    func migratingLegacyConfiguration() -> Self {
        var migrated = self
        if healthKitParams.sampleType == .vo2Max {
            if healthKitParams.units == .count { migrated.healthKitParams.units = .oxygenUptake }
            if healthKitParams.aggregation == .sum { migrated.healthKitParams.aggregation = .avg }
        }
        if healthKitParams.sampleType == .dietaryEnergyConsumed, healthKitParams.units == .mgrams {
            migrated.healthKitParams.units = .kilocalorie
        }
        return migrated
    }
}
