import Testing
import Foundation
import HealthKit
import UIKit
@testable import AnyProgress

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

    @Test func progressUsesLowerBoundAndHandlesInvalidRanges() {
        #expect(Progress(absolute: 50, maxAbsolute: 100, minAbsolute: 20).normalized == 0.375)
        #expect(Progress(absolute: 50, maxAbsolute: 100, minAbsolute: 20, reversed: true).normalized == 0.625)
        #expect(Progress(absolute: 10, maxAbsolute: 10, minAbsolute: 10).normalized == 0)
        #expect(Progress(absolute: .infinity, maxAbsolute: 100, minAbsolute: 0).normalized == 0)
        #expect(RectangularShape.point(for: .infinity).x == 0.5)
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
