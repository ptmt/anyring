import Testing
import SwiftUI
import WidgetKit
import XCTest
import Foundation
import HealthKit
import UIKit
import SwiftUI
@testable import AnyProgress

/// Render the production widget view, not a reimplementation, at accessory sizes.
final class WidgetRenderingTests: XCTestCase {
    @MainActor
    func testPrivacyDoesNotRevealRingShapesOrProgress() throws {
        func render(_ values: [Double]) throws -> Data {
            let entry = SimpleEntry(date: Date(), rings: RingWrapper(values.map {
                RingSnapshot(progress: $0, mainColor: CodableColor(.green))
            }), names: ["Private", "Steps", "Energy"], readingDate: nil)
            let renderer = ImageRenderer(content: RingWidgetEntryView(entry: entry, familyOverride: .accessoryCircular)
                .redacted(reason: .privacy).frame(width: 76, height: 76))
            return try XCTUnwrap(renderer.uiImage?.pngData())
        }
        XCTAssertEqual(try render([0, 0, 0]), try render([0.25, 0.5, 1.5]))
    }

    @MainActor
    func testAccessoryFamiliesRenderDataEmptyAndPrivacyStates() throws {
        let rings = RingWrapper([0.0, 0.5, 1.5].map { RingSnapshot(progress: $0, mainColor: CodableColor(.green)) })
        let populated = SimpleEntry(date: Date(), rings: rings,
                                    names: ["Recovery", "Steps", "Energy"], readingDate: Date())
        let empty = SimpleEntry(date: Date(), rings: nil, names: [], readingDate: nil)
        for (family, size) in [(WidgetFamily.accessoryCircular, CGSize(width: 76, height: 76)),
                               (.accessoryRectangular, CGSize(width: 170, height: 76)),
                               (.accessoryInline, CGSize(width: 250, height: 26))] {
            for (state, entry) in [("progress", populated), ("empty", empty), ("private", populated)] {
                let view = RingWidgetEntryView(entry: entry, familyOverride: family)
                    .environment(\.colorScheme, .dark)
                    .redacted(reason: state == "private" ? .privacy : [])
                    .frame(width: size.width, height: size.height)
                    .background(.black)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 3
                let image = try XCTUnwrap(renderer.uiImage)
                XCTAssertEqual(image.size, size)
                let attachment = XCTAttachment(image: image)
                attachment.name = "\(family)-\(state)"
                attachment.lifetime = .keepAlways
                add(attachment)
            }
        }
    }
}

@Suite @MainActor
struct ConfigurationTests {
    private func store() -> UserDefaultsConfigurationPersistence {
        let defaults = UserDefaults(suiteName: "AnyRingTests.\(UUID().uuidString)")!
        return UserDefaultsConfigurationPersistence(userDefaults: defaults)
    }

    @Test func queuedOlderDeliveryCannotReplaceLiveReply() {
        let config = UserDefaultsConfigurationPersistence.defaultConfig
        var state = ConfigurationSyncState()
        let accepted = state.receive(ConfigurationSnapshot(config: config, revision: 20))
        #expect(accepted)
        var older = config; older.global.days = 7
        let rejectedOlder = state.receive(ConfigurationSnapshot(config: older, revision: 10))
        #expect(!rejectedOlder)
        let rejectedDuplicate = state.receive(ConfigurationSnapshot(config: older, revision: 20))
        #expect(!rejectedDuplicate)
        #expect(state.latest?.config.global.days == 3)
    }

    @Test func revisionAndSettingsSurviveRelaunch() {
        let persistence = store()
        persistence.persist(config: UserDefaultsConfigurationPersistence.defaultConfig)
        var latest = persistence.restore()!
        latest.global.days = 7
        persistence.persist(config: latest)
        let saved = persistence.restoreSnapshot()!
        var restored = ConfigurationSyncState(latest: saved)
        let acceptedOlder = restored.receive(ConfigurationSnapshot(config: UserDefaultsConfigurationPersistence.defaultConfig, revision: saved.revision - 1))
        #expect(!acceptedOlder)
        #expect(restored.latest?.config.global.days == 7)
        persistence.persist(config: latest)
        #expect(persistence.restoreSnapshot()?.revision == saved.revision)
    }

    @Test func periodAndRingEditsUpdateTheSyncSource() {
        let model = AnyRingViewModel(persistence: store(), dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        var published: AnyRingConfig?
        model.onConfigurationChanged = { published = $0 }
        model.updatePeriod(days: 7)
        #expect(model.config.global.days == 7)
        #expect(published?.global.days == 7)
        var ring = model.rings!.first.configuration
        ring.maxValue = 200
        model.rings!.first.update(config: ring)
        #expect(model.config.configs[0].maxValue == 200)
        #expect(model.persistence.restore()?.configs[0].maxValue == 200)
        #expect(published?.configs[0].maxValue == 200)
    }

    @Test func receivedSnapshotReplacesVisibleSettingsImmediately() {
        let model = AnyRingViewModel(persistence: store(), dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        var changed = model.config
        changed.global.days = 7
        changed.configs[0].maxValue = 500
        model.apply(ConfigurationSnapshot(config: changed, revision: 50))
        #expect(model.globalConfig.days == 7)
        #expect(model.rings?.first.configuration.maxValue == 500)
        #expect(model.rings?.first.globalConfig.days == 7)
        #expect(model.persistence.restoreSnapshot()?.revision == 50)
    }

    @Test func oldColorArchivesMigrateWithoutLosingConfiguration() throws {
        let data = try NSKeyedArchiver.archivedData(withRootObject: UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1), requiringSecureCoding: false)
        let color = try JSONDecoder().decode(CodableColor.self, from: JSONEncoder().encode(data))
        #expect(abs(color.red - 0.2) < 0.001)
        #expect(abs(color.green - 0.4) < 0.001)
        #expect(abs(color.blue - 0.6) < 0.001)
        let roundTrip = try JSONDecoder().decode(CodableColor.self, from: JSONEncoder().encode(color))
        #expect(roundTrip.red == color.red)
    }

    @Test func legacyConfigurationMigratesInPlace() throws {
        let defaults = UserDefaults(suiteName: "AnyRingTests.\(UUID().uuidString)")!
        let configuration = UserDefaultsConfigurationPersistence.defaultConfig
        defaults.set(try JSONEncoder().encode(configuration), forKey: UserDefaultsConfigurationPersistence.key)
        let persistence = UserDefaultsConfigurationPersistence(userDefaults: defaults)
        #expect(persistence.restore() == configuration)
        persistence.persist(config: persistence.restore()!)
        #expect(persistence.restoreSnapshot()?.config == configuration)
    }

    @Test func malformedRingIDsAndPeriodsAreRejected() throws {
        let data = try JSONEncoder().encode(UserDefaultsConfigurationPersistence.defaultConfig)
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        object["global"] = ["days": 0]
        let invalid = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(AnyRingConfig.self, from: invalid) }
    }

    @Test func maximumStatisticsUsesMaximumOption() {
        #expect(DeviceHealthKitDataSource.statisticsOption(for: .max) == .discreteMax)
    }

    @Test func widgetLinksRejectUnknownRingsAndUnrelatedURLs() {
        #expect(WidgetDestination(url: URL(string: "anyprogress://rings")!) == .overview)
        #expect(WidgetDestination(url: URL(string: "anyprogress://ring/0")!) == .ring(.first))
        #expect(WidgetDestination(url: URL(string: "anyprogress://ring/2")!) == .ring(.third))
        for value in ["https://ring/0", "anyprogress://ring/3", "anyprogress://ring/nope", "anyprogress://other", "anyprogress://rings/0"] {
            #expect(WidgetDestination(url: URL(string: value)!) == nil)
        }
        #expect(WidgetDestination(url: WidgetDestination.ring(.second).url) == .ring(.second))
    }

    @Test func widgetReadingUsesConfiguredOrderGoalsAndPeriod() async throws {
        let persistence = store()
        var config = UserDefaultsConfigurationPersistence.defaultConfig
        config.global.days = 1
        config.configs[0].name = "My recovery"
        config.configs[0].maxValue = 220
        config.configs[1].maxValue = 10000
        config.configs[2].maxValue = 500
        persistence.persist(config: config)
        let model = AnyRingViewModel(persistence: persistence, dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        let rings: RingWrapper<RingSnapshot>? = try await model.getSnapshots()
        #expect(model.config.configs.first?.name == "My recovery")
        #expect(rings?.first.progress == 0.5)
        #expect(rings?.second.progress == 0.51)
        #expect(rings?.third.progress == 2.2)
        model.refreshWidgetSnapshot()
        // A changed goal must not accept an asynchronous reading of the previous configuration.
        config.configs[0].maxValue = 440
        persistence.persist(config: config)
        await Task.yield()
        #expect(persistence.widgetCache.restoreReading(config: config) == nil)
    }

    @Test func widgetCacheRequiresMatchingSavedConfigurationAndRetainsReadingDate() {
        let defaults = UserDefaults(suiteName: "WidgetCacheTests.\(UUID().uuidString)")!
        let cache = SimpleCache(storage: defaults)
        let config = UserDefaultsConfigurationPersistence.defaultConfig
        let rings = RingWrapper([0.0, 0.5, 1.5].map { RingSnapshot(progress: $0, mainColor: CodableColor(.green)) })
        let readAt = Date(timeIntervalSince1970: 1234)
        #expect(cache.restoreLastSnapshot(config: config) == nil)
        cache.store(lastSnapshot: rings, config: config, date: readAt)
        #expect(cache.restoreReading(config: config)?.date == readAt)
        #expect(cache.restoreLastSnapshot(config: config)?.third.progress == 1.5)
        var changed = config
        changed.configs[0].maxValue += 1
        #expect(cache.restoreLastSnapshot(config: changed) == nil)
        #expect(cache.restoreLastSnapshot(config: nil) == nil)
        cache.store(lastSnapshot: nil, config: config)
        #expect(cache.restoreReading(config: config)?.date == readAt)
    }

    @Test func invalidSnapshotProgressCannotBeShownAsARealPercentage() {
        #expect(RingSnapshot(progress: .nan, mainColor: CodableColor(.green)).percentageText == "—")
        #expect(RingSnapshot(progress: .infinity, mainColor: CodableColor(.green)).percentageText == "—")
        #expect(RingSnapshot(progress: -0.5, mainColor: CodableColor(.green)).percentageText == "0%")
        #expect(RingSnapshot(progress: 1.5, mainColor: CodableColor(.green)).percentageText == "150%")
        #expect(RingSnapshot(progress: 0, mainColor: CodableColor(.green)).percentageText == "0%")
    }

    @Test func progressUsesLowerBoundAndHandlesInvalidRanges() {
        #expect(Progress(absolute: 50, maxAbsolute: 100, minAbsolute: 20).normalized == 0.375)
        #expect(Progress(absolute: 50, maxAbsolute: 100, minAbsolute: 20, reversed: true).normalized == 0.625)
        #expect(Progress(absolute: 10, maxAbsolute: 10, minAbsolute: 10).normalized == 0)
        #expect(Progress(absolute: .infinity, maxAbsolute: 100, minAbsolute: 0).normalized == 0)
        #expect(RectangularShape.point(for: .infinity).x == 0.5)
    }
}

/// HealthKit delivers authorization and query results on arbitrary background queues.
/// Synthetic values only: never reads or writes the user's Health database.
@MainActor
final class BackgroundHealthDataSource: HealthKitDataSource {
    enum Delivery: Sendable { case main, background }
    enum Reading: Sendable { case populated, empty, denied }
    let delivery: Delivery
    let reading: Reading
    let authorization: Result<Bool, Error>
    private(set) var authorized = false
    private(set) var readCount = 0

    init(delivery: Delivery = .background, reading: Reading = .populated,
         authorization: Result<Bool, Error> = .success(true)) {
        self.delivery = delivery
        self.reading = reading
        self.authorization = authorization
    }

    func isAvailable() -> Bool { true }
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                self.authorized = (try? self.authorization.get()) == true
                let result = self.authorization
                self.deliver { continuation.resume(with: result) }
            }
        }
    }
    private func deliver(_ body: @escaping @Sendable () -> Void) {
        let queue = delivery == .main ? DispatchQueue.main : DispatchQueue.global()
        queue.asyncAfter(deadline: .now() + 0.02, execute: body)
    }
    func fetchStatistics(withStart: Date, to: Date, ofType: HKSampleType,
                         unit: HKUnit, aggregation: Aggregation) async throws -> Double {
        readCount += 1
        let result: Result<Double, Error>
        if !authorized || reading == .empty { result = .failure(HealthDataError.noSamples) }
        else if reading == .denied { result = .failure(HKError(.errorAuthorizationDenied)) }
        else { result = .success(42) }
        return try await withCheckedThrowingContinuation { continuation in
            self.deliver { continuation.resume(with: result) }
        }
    }
}

@Suite @MainActor
struct BackgroundHealthDeliveryTests {
    @Test(arguments: [BackgroundHealthDataSource.Delivery.main, .background],
          [BackgroundHealthDataSource.Reading.populated, .empty, .denied])
    func authorizationThenReadHandlesNewAndLegacyConfiguration(
        delivery: BackgroundHealthDataSource.Delivery, reading: BackgroundHealthDataSource.Reading
    ) async throws {
        for legacy in [false, true] {
            let suite = "BackgroundHealthTests.\(UUID().uuidString)"
            let defaults = UserDefaults(suiteName: suite)!
            defer { defaults.removePersistentDomain(forName: suite) }
            let persistence = UserDefaultsConfigurationPersistence(userDefaults: defaults)
            var expected = UserDefaultsConfigurationPersistence.defaultConfig
            if legacy {
                var ring = expected.configs[0] as! HealthKitProvider.Configuration
                ring.healthKitParams = vo2Max
                ring.healthKitParams.units = .count
                ring.healthKitParams.aggregation = .sum
                expected.configs[0] = ring
                let encoder = JSONEncoder(); encoder.userInfo[.legacyColorArchive] = true
                defaults.set(try encoder.encode(expected), forKey: UserDefaultsConfigurationPersistence.key)
                expected = persistence.restore()!
            }
            let source = BackgroundHealthDataSource(delivery: delivery, reading: reading)
            let model = AnyRingViewModel(persistence: persistence, dataSource: source)
            // Match AppController's first-run persistence, after model creation.
            persistence.persist(config: model.config)
            for _ in 0..<100 {
                if source.readCount >= 9 && model.rings?.list.allSatisfy({ !$0.isRefreshing }) == true { break }
                try await Task.sleep(for: .milliseconds(20))
            }
            #expect(source.authorized)
            #expect(source.readCount >= 9)
            #expect(model.config == expected)
            #expect(!model.showingAlert)
            if reading == .populated {
                for _ in 0..<100 {
                    if persistence.widgetCache.restoreReading(config: model.config) != nil { break }
                    try await Task.sleep(for: .milliseconds(20))
                }
                #expect(model.rings?.list.allSatisfy({ $0.progress.absolute == 42 && $0.error == nil }) == true)
                #expect(persistence.widgetCache.restoreReading(config: model.config) != nil)
            } else {
                #expect(model.rings?.list.allSatisfy({ $0.error != nil }) == true)
                #expect(persistence.widgetCache.restoreReading(config: model.config) == nil)
            }
        }
    }

    @Test(arguments: [BackgroundHealthDataSource.Delivery.main, .background], [false, true])
    func unsuccessfulAuthorizationDoesNotRefresh(delivery: BackgroundHealthDataSource.Delivery,
                                                 throwsError: Bool) async throws {
        let suite = "BackgroundHealthTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let source = BackgroundHealthDataSource(delivery: delivery,
            authorization: throwsError ? .failure(HKError(.errorAuthorizationDenied)) : .success(false))
        let model = AnyRingViewModel(persistence: UserDefaultsConfigurationPersistence(userDefaults: defaults), dataSource: source)
        for _ in 0..<100 {
            if model.showingAlert { break }
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(model.showingAlert)
        #expect((model.authorizationError != nil) == throwsError)
        #expect(source.readCount == 3) // Only initial reads, not an authorization-triggered refresh.
    }
}

/// Deliberately ignores cancellation to exercise late results from superseded work.
@MainActor
private final class ControlledHealthDataSource: HealthKitDataSource {
    struct Read {
        let type: HKSampleType
        let start: Date
        let end: Date
        let complete: (Result<Double, Error>) -> Void
    }
    var reads: [Read] = []
    var permissions: [(Result<Bool, Error>) -> Void] = []
    func isAvailable() -> Bool { true }
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            self.permissions.append { continuation.resume(with: $0) }
        }
    }
    func fetchStatistics(withStart start: Date, to end: Date, ofType type: HKSampleType,
                         unit: HKUnit, aggregation: Aggregation) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            self.reads.append(Read(type: type, start: start, end: end, complete: { continuation.resume(with: $0) }))
        }
    }
}

@MainActor
private final class CancellableHealthDataSource: HealthKitDataSource {
    var activeReads = 0
    var cancelledReads = 0
    func isAvailable() -> Bool { true }
    func requestPermissions(permissions: Set<HKObjectType>) async throws -> Bool { true }
    func fetchStatistics(withStart: Date, to: Date, ofType: HKSampleType,
                         unit: HKUnit, aggregation: Aggregation) async throws -> Double {
        activeReads += 1
        defer { activeReads -= 1 }
        do { try await Task.sleep(for: .seconds(30)) }
        catch { cancelledReads += 1; throw error }
        return 42
    }
}

@Suite @MainActor
struct HealthRefreshTests {
    private func model(_ source: ControlledHealthDataSource, authorize: Bool = false) -> AnyRingViewModel {
        let persistence = UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "RefreshTests.\(UUID())")!)
        let model = AnyRingViewModel(persistence: persistence, dataSource: source, requestAuthorization: authorize)
        persistence.persist(config: model.config)
        return model
    }

    private func settle() async throws { try await Task.sleep(for: .milliseconds(50)) }

    @Test func shapeEditRefreshesTheInvalidatedWidgetCache() async throws {
        let persistence = UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "ShapeCacheTests.\(UUID())")!)
        let model = AnyRingViewModel(persistence: persistence, dataSource: MockHealthKitDataSource())
        persistence.persist(config: model.config)
        for _ in 0..<100 {
            if persistence.widgetCache.restoreReading(config: model.config) != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(persistence.widgetCache.restoreReading(config: model.config) != nil)
        model.updateShape(.heart)
        for _ in 0..<100 {
            if persistence.widgetCache.restoreReading(config: model.config) != nil { break }
            try await Task.sleep(for: .milliseconds(10))
        }
        let reading = try #require(persistence.widgetCache.restoreReading(config: model.config))
        #expect(reading.configuration.global.shape == .heart)
        #expect(reading.rings.count == 3)
        #expect(reading.rings[1].progress == 5100 / model.config.configs[1].maxValue)
    }

    @Test func widgetRefreshRejectsLateResultsAndRetainsLastGoodReadingOnFailure() async throws {
        let source = ControlledHealthDataSource()
        let model = model(source)
        try await settle()
        source.reads.forEach { $0.complete(.success(1)) }
        model.refreshWidgetSnapshot()
        try await settle()
        let obsolete = Array(source.reads.suffix(3))
        model.updateShape(.heart)
        model.refreshWidgetSnapshot()
        try await settle()
        let current = Array(source.reads.suffix(3))
        current.forEach { $0.complete(.success(42)) }
        try await settle()
        let saved = try #require(model.persistence.widgetCache.restoreReading(config: model.config))
        #expect(saved.configuration.global.shape == .heart)
        obsolete.forEach { $0.complete(.success(999)) }
        try await settle()
        #expect(model.persistence.widgetCache.restoreReading(config: model.config)?.date == saved.date)
        #expect(model.persistence.widgetCache.restoreReading(config: model.config)?.rings[1].progress == 42 / model.config.configs[1].maxValue)
        model.refreshWidgetSnapshot()
        try await settle()
        source.reads.suffix(3).forEach { $0.complete(.failure(HealthDataError.noSamples)) }
        try await settle()
        #expect(model.persistence.widgetCache.restoreReading(config: model.config)?.date == saved.date)
        #expect(model.persistence.widgetCache.restoreReading(config: model.config)?.rings[1].progress == 42 / model.config.configs[1].maxValue)
    }

    @Test func simultaneousSnapshotsReadAllMetricsIndependently() async throws {
        let source = ControlledHealthDataSource()
        let model = model(source)
        // Wait for registration, not a fixed scheduling delay: the rendering suite
        // can occupy MainActor long enough for a 50 ms sleep to finish first.
        let initialDeadline = ContinuousClock.now.advanced(by: .seconds(10))
        while source.reads.count < 3 && ContinuousClock.now < initialDeadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        try #require(source.reads.count == 3)
        source.reads.forEach { $0.complete(.success(1)) }
        var results: [RingWrapper<RingSnapshot>] = []
        let first = Task { results.append(try await model.getSnapshots()) }
        let second = Task { results.append(try await model.getSnapshots()) }
        let snapshotDeadline = ContinuousClock.now.advanced(by: .seconds(10))
        while source.reads.count < 9 && ContinuousClock.now < snapshotDeadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        // Abort before completing anything if registration failed: suffix(6) on
        // the original three reads would resume their continuations twice.
        try #require(source.reads.count == 9)
        #expect(Set(source.reads.suffix(6).map(\.type)).count == 3)
        for read in source.reads.suffix(6).reversed() { read.complete(.success(42)) }
        try await first.value
        try await second.value
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.list.count == 3 })
    }

    @Test func supersededRefreshCannotReplaceProgressOrError() async throws {
        let source = ControlledHealthDataSource()
        let model = model(source)
        try await settle()
        let ring = model.rings!.first
        var changed = ring.configuration
        changed.maxValue = 200
        ring.update(config: changed)
        try await settle()
        #expect(source.reads.count == 4)
        source.reads[3].complete(.success(80))
        try await settle()
        source.reads[0].complete(.failure(HealthDataError.noSamples))
        try await settle()
        #expect(ring.progress.absolute == 80)
        #expect(ring.progress.maxAbsolute == 200)
        #expect(ring.error == nil)
        #expect(!ring.isRefreshing)
        ring.refresh()
        try await settle()
        source.reads.last!.complete(.failure(HealthDataError.noSamples))
        try await settle()
        #expect(ring.error is HealthDataError)
        #expect(ring.progress.absolute == 80) // Keep last good reading on error.
        source.reads[1...2].forEach { $0.complete(.success(1)) }
    }

    @Test func staleAuthorizationCannotRefreshReplacementConfiguration() async throws {
        let source = ControlledHealthDataSource()
        let model = model(source, authorize: true)
        try await settle()
        model.updateProviders()
        try await settle()
        #expect(source.permissions.count == 2)
        source.permissions[0](.failure(HealthDataError.noSamples))
        source.permissions[1](.success(false))
        try await settle()
        #expect(model.showingAlert)
        #expect(model.authorizationError == nil)
        #expect(source.reads.count == 6)
        source.reads.forEach { $0.complete(.success(1)) }
    }

    @Test func cancellationStopsOnlyTheOwningSnapshotQueries() async throws {
        let source = CancellableHealthDataSource()
        let persistence = UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "CancelTests.\(UUID())")!)
        var model: AnyRingViewModel? = AnyRingViewModel(persistence: persistence, dataSource: source, requestAuthorization: false)
        try await settle()
        let first = Task { [model = model!] in try await model.getSnapshots() }
        let second = Task { [model = model!] in try await model.getSnapshots() }
        try await settle()
        #expect(source.activeReads == 9)
        first.cancel()
        do { _ = try await first.value; Issue.record("Cancelled snapshot returned progress") }
        catch { #expect(error is CancellationError) }
        #expect(source.cancelledReads == 3)
        #expect(source.activeReads == 6)
        second.cancel()
        do { _ = try await second.value; Issue.record("Cancelled snapshot returned progress") }
        catch { #expect(error is CancellationError) }
        #expect(source.activeReads == 3)
        model = nil
        try await settle()
        #expect(source.activeReads == 0)
        #expect(source.cancelledReads == 9)
    }

    @Test func providerPassesCalendarWindowAndRejectsAlreadyCancelledRead() async throws {
        let source = ControlledHealthDataSource()
        let config = UserDefaultsConfigurationPersistence.defaultConfig.configs[0]
        let provider = HealthKitProvider(dataSource: source, config: config, configPersistence: MockConfigurationPersistence())
        let task = Task { try await provider.calculateProgress(providerConfig: config, globalConfig: GlobalConfiguration(days: 7)) }
        try await settle()
        let read = try #require(source.reads.first)
        let expected = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: -6, to: read.end)!)
        #expect(read.start == expected)
        read.complete(.success(42))
        #expect(try await task.value.absolute == 42)
        let cancelled = Task { try await provider.calculateProgress(providerConfig: config, globalConfig: .Default) }
        cancelled.cancel()
        do { _ = try await cancelled.value; Issue.record("Cancelled read returned progress") }
        catch { #expect(error is CancellationError) }
        #expect(source.reads.count == 1)
    }

    @Test func snapshotRetainsConfigurationAtRequestStart() async throws {
        let source = ControlledHealthDataSource()
        let model = model(source)
        try await settle()
        let original = model.config.configs[0].appearance
        var result: RingWrapper<RingSnapshot>?
        let snapshot = Task { result = try await model.getSnapshots() }
        try await settle()
        var changed = model.rings!.first.configuration
        changed.appearance.mainColor = CodableColor(.purple)
        changed.maxValue = 999
        model.rings!.first.update(config: changed)
        try await settle()
        source.reads.forEach { $0.complete(.success(42)) }
        try await settle()
        try await snapshot.value
        #expect(result?.first.mainColor.red == original.mainColor.red)
        #expect(result?.first.mainColor.green == original.mainColor.green)
        #expect(result?.first.mainColor.blue == original.mainColor.blue)
        #expect(model.persistence.restore()?.configs[0].maxValue == 999)
    }
}

import WatchConnectivity

@MainActor
private final class FakeWatchTransport: WatchConnectivityTransport {
    var isSupported = true
    var activationState = WCSessionActivationState.notActivated
    var isReachable = false
    var isWatchAppInstalled = true
    var isPaired = true
    var receivedApplicationContext: [String: Any] = [:]
    var contexts: [[String: Any]] = []
    var messages: [[String: Any]] = []
    var backgroundSnapshots: [[String: Any]] = []
    var activations = 0
    var failsContext = false
    var errorHandler: (@Sendable (Error) -> Void)?
    weak var delegate: (any WCSessionDelegate)?
    weak var peer: WatchConnectivityCoordinator?
    func configure(delegate: any WCSessionDelegate) { self.delegate = delegate }
    func activate() { activations += 1 }
    func updateApplicationContext(_ context: [String: Any]) throws {
        if failsContext { throw CocoaError(.fileWriteUnknown) }
        contexts.append(context)
    }
    func queueBackgroundSnapshot(_ payload: [String: Any]) { backgroundSnapshots.append(payload) }
    func sendMessage(_ message: [String: Any], replyHandler: (@Sendable ([String: Any]) -> Void)?, errorHandler: (@Sendable (Error) -> Void)?) {
        messages.append(message)
        self.errorHandler = errorHandler
        if let peer {
            if let replyHandler { peer.session(.default, didReceiveMessage: message, replyHandler: replyHandler) }
            else { peer.session(.default, didReceiveMessage: message) }
        }
    }
}

@Suite @MainActor
struct WatchSyncTests {
    private func store() -> UserDefaultsConfigurationPersistence {
        UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "WatchSyncTests.\(UUID().uuidString)")!)
    }

    private func payload(_ config: AnyRingConfig, revision: Double) throws -> [String: Any] {
        ["snapshot": try JSONEncoder().encode(ConfigurationSnapshot(config: config, revision: revision))]
    }

    @Test func phoneRetainsLatestEditBeforeActivation() throws {
        let transport = FakeWatchTransport()
        let sync = WatchConnectivityCoordinator(persistence: store(), transport: transport, role: .phone) { _ in }
        sync.start()
        var config = UserDefaultsConfigurationPersistence.defaultConfig
        config.global.days = 5; sync.publish(config)
        config.global.days = 7; sync.publish(config)
        #expect(transport.contexts.isEmpty)
        transport.activationState = .activated
        sync.activationCompleted()
        let received = try JSONDecoder().decode(ConfigurationSnapshot.self, from: transport.contexts.last!["snapshot"] as! Data)
        #expect(received.config.global.days == 7)
        #expect(transport.backgroundSnapshots.count == 1)
    }

    @Test func phoneQueuesUpdatesWhenWatchIsNotReachable() {
        let transport = FakeWatchTransport(); transport.activationState = .activated
        let sync = WatchConnectivityCoordinator(persistence: store(), transport: transport, role: .phone) { _ in }
        sync.start()
        #expect(transport.contexts.count == 1)
        #expect(transport.messages.isEmpty)
        transport.isReachable = true
        sync.refresh()
        #expect(transport.messages.count == 1)
        #expect(transport.backgroundSnapshots.count == 1)
        var changed = UserDefaultsConfigurationPersistence.defaultConfig; changed.global.days = 7
        sync.publish(changed)
        #expect(transport.backgroundSnapshots.count == 2)
    }

    @Test func activationAfterWatchInstallationReplaysLatestSettings() {
        let transport = FakeWatchTransport(); transport.activationState = .activated; transport.isWatchAppInstalled = false
        let sync = WatchConnectivityCoordinator(persistence: store(), transport: transport, role: .phone) { _ in }
        sync.start()
        #expect(transport.contexts.isEmpty)
        transport.isWatchAppInstalled = true
        sync.refresh()
        #expect(transport.contexts.count == 1)
    }

    @Test func failedContextSendIsRetried() {
        let transport = FakeWatchTransport(); transport.activationState = .activated; transport.failsContext = true
        let sync = WatchConnectivityCoordinator(persistence: store(), transport: transport, role: .phone) { _ in }
        sync.start()
        #expect(transport.contexts.isEmpty)
        transport.failsContext = false; sync.refresh()
        #expect(transport.contexts.count == 1)
    }

    @Test func offlineColdLaunchAppliesCachedContextBeforeAnyViewAppears() throws {
        let persistence = store()
        let model = AnyRingViewModel(persistence: persistence, dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        var changed = model.config; changed.global.days = 7
        let transport = FakeWatchTransport(); transport.activationState = .activated
        transport.receivedApplicationContext = try payload(changed, revision: 200)
        let sync = WatchConnectivityCoordinator(persistence: persistence, transport: transport, role: .watch) { model.apply($0) }
        sync.start()
        #expect(model.globalConfig.days == 7)
        #expect(model.persistence.restoreSnapshot()?.revision == 200)
        #expect(transport.messages.isEmpty)
    }

    @Test func foregroundAndReachabilityRequestLatestSettings() {
        let transport = FakeWatchTransport(); transport.activationState = .activated
        let sync = WatchConnectivityCoordinator(persistence: store(), transport: transport, role: .watch) { _ in }
        sync.start()
        #expect(transport.messages.isEmpty)
        transport.isReachable = true; sync.refresh()
        #expect(transport.messages.count == 1)
        sync.refresh()
        #expect(transport.messages.count == 1) // Concurrent refresh requests coalesce.
    }

    @Test func staleBackgroundContextCannotUndoNewerMessage() throws {
        let persistence = store()
        var config = UserDefaultsConfigurationPersistence.defaultConfig; config.global.days = 7
        let transport = FakeWatchTransport(); transport.activationState = .activated
        let sync = WatchConnectivityCoordinator(persistence: persistence, transport: transport, role: .watch) { persistence.persist(snapshot: $0) }
        let latest = try payload(config, revision: 300)
        sync.accept(snapshotData: latest["snapshot"] as? Data, legacyConfig: nil)
        transport.receivedApplicationContext = try payload(UserDefaultsConfigurationPersistence.defaultConfig, revision: 200)
        sync.start()
        #expect(persistence.restore()?.global.days == 7)
    }

    @Test func malformedPayloadDoesNotReplaceSavedSettings() {
        let persistence = store()
        let config = UserDefaultsConfigurationPersistence.defaultConfig
        persistence.persist(snapshot: ConfigurationSnapshot(config: config, revision: 200))
        let sync = WatchConnectivityCoordinator(persistence: persistence, transport: FakeWatchTransport(), role: .watch) { persistence.persist(snapshot: $0) }
        sync.accept(snapshotData: Data("broken json".utf8), legacyConfig: nil)
        #expect(persistence.restore() == config)
        #expect(persistence.restoreSnapshot()?.revision == 200)
    }
}

@Suite @MainActor
struct HealthDataRegressionTests {
    @Test func widgetMissingHealthSamplesAreUnavailableRatherThanZero() {
        #expect(throws: HealthDataError.self) {
            try DeviceHealthKitDataSource.quantityValue(nil, unit: .count(), requireSamples: true)
        }
        #expect((try? DeviceHealthKitDataSource.quantityValue(HKQuantity(unit: .count(), doubleValue: 0),
                                                           unit: .count(), requireSamples: true)) == 0)
    }

    @Test func incompatibleUnitsReturnAnErrorInsteadOfAnObjectiveCException() {
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: 200)
        #expect(throws: HealthDataError.self) { try DeviceHealthKitDataSource.quantityValue(quantity, unit: .gram()) }
        #expect((try? DeviceHealthKitDataSource.quantityValue(quantity, unit: .kilocalorie())) == 200)
    }

    @Test func invalidLegacyVO2SettingsAreMigrated() throws {
        var config = UserDefaultsConfigurationPersistence.defaultConfig
        var ring = config.configs[0] as! HealthKitProvider.Configuration
        ring.healthKitParams = vo2Max
        ring.healthKitParams.units = .count
        ring.healthKitParams.aggregation = .sum
        config.configs[0] = ring
        let decoded = try JSONDecoder().decode(AnyRingConfig.self, from: JSONEncoder().encode(config))
        let migrated = decoded.configs[0] as! HealthKitProvider.Configuration
        #expect(migrated.healthKitParams.units == .oxygenUptake)
        #expect(migrated.healthKitParams.aggregation == .avg)
    }

    @Test func compatibilityPayloadStillUsesArchivedColors() throws {
        let config = UserDefaultsConfigurationPersistence.defaultConfig
        let encoder = JSONEncoder(); encoder.userInfo[.legacyColorArchive] = true
        let data = try encoder.encode(config)
        let object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let first = object["first"] as! [String: Any]
        let appearance = first["appearance"] as! [String: Any]
        #expect(appearance["mainColor"] is String)
        #expect(try JSONDecoder().decode(AnyRingConfig.self, from: data) == config)
    }
}

@Suite @MainActor
struct VisualizationAndSyncReceiptTests {
    private func store() -> UserDefaultsConfigurationPersistence {
        UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "VisualizationTests.\(UUID().uuidString)")!)
    }

    @Test func oldConfigurationsDefaultToRoundedCorners() throws {
        let data = try JSONEncoder().encode(UserDefaultsConfigurationPersistence.defaultConfig)
        var object = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        object["global"] = ["days": 5]
        let decoded = try JSONDecoder().decode(AnyRingConfig.self, from: JSONSerialization.data(withJSONObject: object))
        #expect(decoded.global.days == 5)
        #expect(decoded.global.shape == .roundedSquare)
    }

    @Test func everyContourIsClosedFiniteAndBounded() {
        let bounds = CGRect(x: 7, y: 11, width: 180, height: 180)
        for shape in RingShape.allCases {
            let contour = RingContour(shape: shape, rect: bounds)
            #expect(contour.length > 0)
            #expect(contour.points.first == contour.points.last)
            #expect(contour.points.allSatisfy { point in
                point.x.isFinite && point.y.isFinite && point.x >= bounds.minX - 0.001 && point.x <= bounds.maxX + 0.001 &&
                point.y >= bounds.minY - 0.001 && point.y <= bounds.maxY + 0.001
            })
            #expect(contour.point(at: .infinity) == contour.points.first)
            #expect(contour.point(at: -1) == contour.points.first)
            #expect(contour.point(at: 1) == contour.points.last)
        }
    }

    @Test func shapeEditIsPersistedPublishedAndAppliedOnWatch() throws {
        let model = AnyRingViewModel(persistence: store(), dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        var published: AnyRingConfig?
        model.onConfigurationChanged = { published = $0 }
        model.updateShape(.heart)
        #expect(model.globalConfig.shape == .heart)
        #expect(model.persistence.restore()?.global.shape == .heart)
        #expect(published?.global.shape == .heart)
        let snapshot = model.persistence.restoreSnapshot()!
        let decoded = try JSONDecoder().decode(ConfigurationSnapshot.self, from: JSONEncoder().encode(snapshot))
        let watch = AnyRingViewModel(persistence: store(), dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        watch.apply(decoded)
        #expect(watch.globalConfig.shape == .heart)
    }

    @Test func allShapeChoicesSurviveConfigurationRoundTrip() throws {
        for shape in RingShape.allCases {
            var config = UserDefaultsConfigurationPersistence.defaultConfig
            config.global.shape = shape
            #expect(try JSONDecoder().decode(AnyRingConfig.self, from: JSONEncoder().encode(config)).global.shape == shape)
        }
    }

    @Test func reversedGoalsAndUnitsUseReadableLabels() {
        let persistence = store()
        let source = MockHealthKitDataSource()
        let reversed = HealthKitProvider.Configuration(ring: .first, healthKitParams: hrConfiguration, appearance: RingAppearance(mainColor: .init(.red)))
        let ring = HealthKitProvider(dataSource: source, config: reversed, configPersistence: persistence).viewModel(globalConfig: .Default)
        #expect(ring.direction == "Lower is better")
        #expect(ring.goalText == "≤ 30 bpm")
        #expect(ring.startingValueText == "From 200 bpm")
        #expect(HKUnitCodable.kilocalorie.displaySymbol(for: .activeEnergyBurned) == "kcal")
        #expect(HKUnitCodable.millisecond.displaySymbol(for: .heartRateVariabilitySDNN) == "ms")
        #expect(HKUnitCodable.count.displaySymbol(for: .stepCount) == "steps")
    }

    @Test func offlineCacheDoesNotPretendToBeANewSync() throws {
        let persistence = store()
        let previousSync = Date(timeIntervalSince1970: 100)
        persistence.persistLastSyncDate(previousSync)
        let transport = FakeWatchTransport(); transport.activationState = .activated
        let snapshot = ConfigurationSnapshot(config: UserDefaultsConfigurationPersistence.defaultConfig, revision: 500)
        transport.receivedApplicationContext = ["snapshot": try JSONEncoder().encode(snapshot)]
        let sync = WatchConnectivityCoordinator(persistence: persistence, transport: transport, role: .watch) { persistence.persist(snapshot: $0) }
        sync.start()
        #expect(sync.lastSyncDate == previousSync)
        let beforeDelivery = Date()
        sync.accept(snapshotData: try JSONEncoder().encode(snapshot), legacyConfig: nil)
        #expect(sync.lastSyncDate! >= beforeDelivery)
        #expect(sync.lastSyncDate == persistence.restoreLastSyncDate())
    }

    @Test func phoneOnlyRecordsAcknowledgementForItsCurrentSettings() {
        let persistence = store()
        let transport = FakeWatchTransport(); transport.activationState = .activated
        let sync = WatchConnectivityCoordinator(persistence: persistence, transport: transport, role: .phone) { _ in }
        sync.start()
        #expect(sync.lastSyncDate == nil)
        let current = persistence.restoreSnapshot()!.revision
        sync.recordAcknowledgement(revision: current - 1)
        #expect(sync.lastSyncDate == nil)
        sync.recordAcknowledgement(revision: current)
        let date = sync.lastSyncDate
        #expect(date != nil)
        #expect(persistence.restoreLastSyncDate() == date)
        let relaunched = WatchConnectivityCoordinator(persistence: persistence, transport: transport, role: .phone) { _ in }
        #expect(relaunched.lastSyncDate == date)
        var changed = UserDefaultsConfigurationPersistence.defaultConfig; changed.global.shape = .circle
        sync.publish(changed)
        sync.recordAcknowledgement(revision: current)
        #expect(sync.lastSyncDate == date)
    }
}


@Suite @MainActor
struct LiveSyncReceiptTests {
    @Test func liveDeliveryAppliesSettingsAndConfirmsBothHeaders() async throws {
        let phoneStore = UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "Receipt.phone.\(UUID().uuidString)")!)
        let watchStore = UserDefaultsConfigurationPersistence(userDefaults: UserDefaults(suiteName: "Receipt.watch.\(UUID().uuidString)")!)
        let phoneTransport = FakeWatchTransport(), watchTransport = FakeWatchTransport()
        phoneTransport.activationState = .activated; watchTransport.activationState = .activated
        phoneTransport.isReachable = true; watchTransport.isReachable = true
        let model = AnyRingViewModel(persistence: watchStore, dataSource: MockHealthKitDataSource(), requestAuthorization: false)
        let phone = WatchConnectivityCoordinator(persistence: phoneStore, transport: phoneTransport, role: .phone) { _ in }
        let watch = WatchConnectivityCoordinator(persistence: watchStore, transport: watchTransport, role: .watch) { model.apply($0) }
        phoneTransport.peer = watch; watchTransport.peer = phone
        phone.start(); watch.start()
        for _ in 0..<100 {
            if phone.lastSyncDate != nil && watch.lastSyncDate != nil { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(phone.lastSyncDate != nil)
        #expect(watch.lastSyncDate != nil)
        var latest = phoneStore.restore()!
        latest.global.shape = .star
        phone.publish(latest)
        for _ in 0..<100 {
            if model.globalConfig.shape == .star { break }
            try await Task.sleep(for: .milliseconds(5))
        }
        #expect(model.globalConfig.shape == .star)
        #expect(watchStore.restore()?.global.shape == .star)
    }
}

@Suite @MainActor
struct RingRenderingTests {
    @Test func circularComplicationsKeepEveryShapeInsideTheWatchFaceMask() throws {
        let rings = RingWrapper([
            RingSnapshot(progress: 1, mainColor: CodableColor(.green)),
            RingSnapshot(progress: 1, mainColor: CodableColor(.pink)),
            RingSnapshot(progress: 1, mainColor: CodableColor(.yellow))
        ])
        for diameter in [CGFloat(32), 44] {
            for shape in RingShape.allCases {
                let graphic = CircularRingGraphic(diameter: diameter, rings: rings, shape: shape)
                func pixels(clipped: Bool) throws -> [UInt8] {
                    let content = Group {
                        if clipped { graphic.clipShape(Circle()) }
                        else { graphic }
                    }.padding(10).background(.black)
                    let renderer = ImageRenderer(content: content)
                    renderer.scale = 2
                    let image = try #require(renderer.cgImage)
                    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
                    try bytes.withUnsafeMutableBytes { buffer in
                        let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
                    }
                    return bytes
                }
                let original = try pixels(clipped: false), masked = try pixels(clipped: true)
                #expect(original.count == masked.count)
                let imageWidth = Int((diameter + 20) * 2)
                var outsideLoss = 0
                var brightestMaskedPixel: UInt8 = 0
                for offset in stride(from: 0, to: original.count, by: 4) {
                    let x = Double((offset / 4) % imageWidth) + 0.5 - Double(imageWidth) / 2
                    let y = Double((offset / 4) / imageWidth) + 0.5 - Double(imageWidth) / 2
                    // At 2× scale, the radius in pixels equals the diameter in points.
                    let outsideCircle = hypot(x, y) >= Double(diameter)
                    for channel in 0..<3 {
                        brightestMaskedPixel = max(brightestMaskedPixel, masked[offset + channel])
                        if outsideCircle {
                            outsideLoss = max(outsideLoss, Int(original[offset + channel]) - Int(masked[offset + channel]))
                        }
                    }
                }
                #expect(outsideLoss <= 8, "The circular mask must not cut off \(shape) rings or their halo at \(diameter) points; lost \(outsideLoss)")
                #expect(brightestMaskedPixel > 200, "The complication still draws its rings")
            }
        }
        let preview = HStack(spacing: 20) {
            VStack(spacing: 12) {
                Text("Before").font(.caption)
                TripleRingView(size: 44, ring1: rings.first, ring2: rings.second, ring3: rings.third, simplified: true)
                    .clipShape(Circle())
            }
            VStack(spacing: 12) {
                Text("Fixed").font(.caption)
                CircularRingGraphic(diameter: 44, rings: rings).clipShape(Circle())
            }
        }.foregroundStyle(.white).padding(20).background(.black)
        let renderer = ImageRenderer(content: preview)
        renderer.scale = 4
        Attachment.record(UIImage(cgImage: try #require(renderer.cgImage)), named: "Circular complication comparison", as: .png)
    }

    @Test func endpointShadingJoinsTheBodyWithoutAnInternalDiscRim() throws {
        // A constant-color tube isolates cap lighting/compositing from the palette gradient.
        let snapshot = RingSnapshot(progress: 0.5, mainColor: CodableColor(Color(red: 0.8, green: 0.4, blue: 0.2)), outerGlow: false)
        let renderer = ImageRenderer(content: RingDrawing(snapshot: snapshot, kind: .roundedSquare, lineWidth: 24, progress: 0.5)
            .frame(width: 200, height: 200).padding(30).background(.white))
        renderer.scale = 4
        let image = try #require(renderer.cgImage)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        // Head is (130,217.5); completed body is to its right. Scan well inside the tube,
        // including the old disc's trailing rim, not the intended leading edge or track.
        var worst = 0
        for y in 858...882 {
            for x in 528...600 {
                for channel in 0..<3 {
                    let offset = (y * image.width + x) * 4 + channel
                    worst = max(worst, abs(Int(bytes[offset]) - Int(bytes[offset + 4])))
                }
            }
        }
        #expect(worst <= 4, "No detached cap rim inside the filled tube; adjacent-pixel jump: \(worst)")
        Attachment.record(UIImage(cgImage: image), named: "Synthetic endpoint continuity", as: .png)
    }

    @Test func gradientEndpointHasNoStraightColorResetInsideTheBody() throws {
        for progress in [0.5, 1.5, 2.5] {
        let snapshot = RingSnapshot(progress: progress, mainColor: CodableColor(.orange), gradient: true,
            secondaryColor: CodableColor(Color(red: 0.65, green: 0.29, blue: 0)), outerGlow: false)
        let renderer = ImageRenderer(content: RingDrawing(snapshot: snapshot, kind: .roundedSquare, lineWidth: 24, progress: progress)
            .frame(width: 200, height: 200).padding(30).background(.white))
        renderer.scale = 4
        let image = try #require(renderer.cgImage)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        try bytes.withUnsafeMutableBytes { buffer in
            let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        var worst = 0
        for y in 858...882 {
            for x in 518...600 {
                for channel in 0..<3 {
                    let offset = (y * image.width + x) * 4 + channel
                    worst = max(worst, abs(Int(bytes[offset]) - Int(bytes[offset + 4])))
                }
            }
        }
        #expect(worst <= 4, "Gradient must not reset to secondary color underneath the tip: \(worst)")
        Attachment.record(UIImage(cgImage: image), named: "Synthetic gradient endpoint continuity \(progress)", as: .png)
        }
    }

    @Test func contourEndpointAndTangentStayOnEveryShapeAcrossLaps() {
        for shape in RingShape.allCases {
            let contour = RingContour(shape: shape, rect: CGRect(x: 10, y: 10, width: 160, height: 160))
            for value in [0.0001, 0.01, 0.25, 0.49, 0.5, 0.51, 0.97, 0.999, 1.0, 1.001, 1.5, 2.5] {
                let state = RingProgress(value)
                let endpoint = contour.point(at: state.head)
                let pathEnd = contour.path(to: state.head).currentPoint!
                #expect(hypot(endpoint.x - pathEnd.x, endpoint.y - pathEnd.y) < 0.00001)
                let tangent = contour.tangent(at: state.head)
                #expect(abs(hypot(tangent.x, tangent.y) - 1) < 0.00001)
                let coverageEnd = contour.path(to: state.coverage).currentPoint!
                let expectedEnd = value < 1 ? endpoint : contour.points[0]
                // CoreGraphics paths store Float coordinates even when CGPoint is Double.
                #expect(hypot(coverageEnd.x - expectedEnd.x, coverageEnd.y - expectedEnd.y) < 0.00002)
            }
        }
    }

    @Test func allShapesRenderEndpointBoundariesAtPhoneWatchAndWidgetScales() throws {
        let start = Date(timeIntervalSince1970: 1000)
        let motion = RingMotion(from: 0, to: 1.25, start: start, duration: 1)
        let frames = (0...8).map { motion.value(at: start.addingTimeInterval(Double($0) / 8)) }
        let values = [0.0, 0.0001, 0.01, 0.49, 0.50, 0.51, 0.97, 0.999, 1, 1.001, 1.25, 2.5] + frames
        for shape in RingShape.allCases {
            for size in [CGFloat(44), 140, 300] {
                var previous: Data?
                for (index, progress) in values.enumerated() {
                    let snapshot = RingSnapshot(progress: progress, mainColor: CodableColor(.orange), gradient: true,
                        secondaryColor: CodableColor(.purple), outerGlow: true, innerGlow: true)
                    let content = RingDrawing(snapshot: snapshot, kind: shape, lineWidth: size / (shape.isPointed ? 20 : 12),
                        progress: progress, simplified: size == 44).frame(width: size, height: size).padding(12).background(.white)
                    let renderer = ImageRenderer(content: content)
                    renderer.scale = 2
                    let image = try #require(renderer.uiImage)
                    let pixels = try #require(image.pngData())
                    #expect(image.size.width == size + 24)
                    if index > 12, let previous { #expect(pixels != previous, "Animation actually redraws \(shape) at \(size)pt") }
                    previous = pixels
                }
                let sheet = HStack(spacing: 8) {
                    ForEach([0.0, 0.001, 0.5, 0.97, 1.0, 1.25], id: \.self) { progress in
                        let snapshot = RingSnapshot(progress: progress, mainColor: CodableColor(.orange), gradient: true,
                            secondaryColor: CodableColor(.purple), outerGlow: true, innerGlow: true)
                        RingDrawing(snapshot: snapshot, kind: shape, lineWidth: size / (shape.isPointed ? 20 : 12),
                            progress: progress, simplified: size == 44).frame(width: size, height: size).padding(12)
                    }
                }.background(.white)
                let renderer = ImageRenderer(content: sheet)
                renderer.scale = 2
                Attachment.record(try #require(renderer.uiImage), named: "Synthetic \(shape.rawValue) \(Int(size))pt 0 near0 half near1 1 over1", as: .png)
            }
        }
    }

    @Test func syntheticEndpointBaseline() throws {
        let colors: [Color] = [.pink, .orange, .yellow]
        let values = [0.48, 0.50, 0.97]
        let fixture = ZStack {
            ForEach(0..<3) { index in
                let color = colors[index]
                let snapshot = RingSnapshot(progress: values[index], mainColor: CodableColor(color), gradient: index > 0,
                    secondaryColor: CodableColor(color.darker(by: 20) ?? color), outerGlow: false)
                RingDrawing(snapshot: snapshot, kind: .roundedSquare, lineWidth: 25, progress: values[index])
                    .frame(width: 300 * [1.0, 0.74, 0.48][index], height: 300 * [1.0, 0.74, 0.48][index])
            }
        }.frame(width: 300, height: 300).padding(30).background(.white)
        let renderer = ImageRenderer(content: fixture)
        renderer.scale = 3
        Attachment.record(UIImage(cgImage: try #require(renderer.cgImage)), named: "Synthetic endpoint baseline", as: .png)
    }

    @Test func motionDrawsIntermediateValuesAndRetargetsWithoutJumping() {
        let start = Date(timeIntervalSince1970: 1_000)
        let sweep = RingMotion(from: 0, to: 1.2, start: start, duration: 1)
        #expect(sweep.value(at: start.addingTimeInterval(-1)) == 0)
        #expect(sweep.value(at: start.addingTimeInterval(0.5)) == 0.6)
        #expect(sweep.value(at: start.addingTimeInterval(1)) == 1.2)
        let halfway = start.addingTimeInterval(0.5)
        let updated = RingMotion(from: sweep.value(at: halfway), to: 0.3, start: halfway, duration: 0.65)
        #expect(updated.value(at: halfway) == sweep.value(at: halfway))
        #expect(updated.value(at: halfway.addingTimeInterval(0.3)) < 0.6)
        #expect(updated.value(at: halfway.addingTimeInterval(1)) == 0.3)
    }

    @Test func progressBeyondTheGoalKeepsTheRingFilledAndWrapsTheTip() {
        let progress = RingProgress(1.25)
        #expect(progress.coverage == 1)
        #expect(progress.head == 0.25)
        #expect(progress.overflow == 0.25)
        #expect(RingProgress(2).head == 0)
        #expect(RingProgress(2).coverage == 1)
        #expect(RingProgress(Double.greatestFiniteMagnitude).head.isFinite)
        for invalid in [Double.nan, .infinity, -.infinity, -1] {
            #expect(RingProgress(invalid).coverage == 0)
        }
    }

    @Test func gradientEndsAtTheTipAndRemainsContinuousAcrossLaps() {
        let partial = RingProgress(0.6)
        #expect(partial.gradientLocation(at: 0) == 0)
        #expect(partial.gradientLocation(at: 0.3) == 0.5)
        #expect(partial.gradientLocation(at: 0.6) == 1)
        let extraLap = RingProgress(1.25)
        #expect(extraLap.gradientLocation(at: extraLap.head) == 1)
        #expect(extraLap.gradientLocation(at: 0.75) == 0.5)
        #expect(abs(RingProgress(1.999).gradientLocation(at: 0.5) - RingProgress(2).gradientLocation(at: 0.5)) < 0.002)
    }

    @Test func gradientRingsKeepTheirCenterClearAndTheirTipInThePrimaryColor() throws {
        let primary = CodableColor(Color(.sRGB, red: 0, green: 0.8, blue: 1))
        let secondary = CodableColor(Color(.sRGB, red: 0.8, green: 0, blue: 0.5))
        let snapshot = RingSnapshot(progress: 0.63, mainColor: primary, gradient: true,
                                    secondaryColor: secondary, outerGlow: true, innerGlow: true)
        for shape in RingShape.allCases {
            let renderer = ImageRenderer(content:
                RingDrawing(snapshot: snapshot, kind: shape, lineWidth: 12, progress: snapshot.progress)
                    .frame(width: 128, height: 128).padding(20).background(.white))
            renderer.scale = 1
            let image = try #require(renderer.cgImage)
            var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
            try bytes.withUnsafeMutableBytes { buffer in
                let context = try #require(CGContext(data: buffer.baseAddress, width: image.width, height: image.height,
                    bitsPerComponent: 8, bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
                context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            func pixel(_ point: CGPoint) -> [UInt8] {
                let offset = (Int(point.y.rounded()) * image.width + Int(point.x.rounded())) * 4
                return Array(bytes[offset..<(offset + 3)])
            }
            #expect(pixel(CGPoint(x: 84, y: 84)).allSatisfy { $0 > 245 }, "Empty center: \(shape)")
            let contour = RingContour(shape: shape, rect: CGRect(x: 26.5, y: 26.5, width: 115, height: 115))
            let tip = pixel(contour.point(at: snapshot.progress))
            #expect(tip[0] < 70 && tip[1] > 160 && tip[2] > 200, "Primary-colored tip: \(shape), \(tip)")
            let midpoint = pixel(contour.point(at: snapshot.progress / 2))
            #expect(midpoint[0] > 50 && midpoint[1] > 50 && midpoint[2] > 150,
                    "Gradient mixes both colors along the outline: \(shape), \(midpoint)")
            if shape != .rectangular {
                let start = contour.point(at: 0), tangent = contour.tangent(at: 0)
                let cap = pixel(CGPoint(x: start.x - tangent.x * 3, y: start.y - tangent.y * 3))
                #expect(cap[0] > 150 && cap[1] < 80 && cap[2] < 200,
                        "Starting cap stays in the secondary color: \(shape), \(cap)")
            }
        }
    }
}
