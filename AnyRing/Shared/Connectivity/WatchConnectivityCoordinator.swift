import Foundation
import Combine
import WatchConnectivity
import OSLog

@MainActor
final class WatchConnectivityCoordinator: NSObject, ObservableObject, WCSessionDelegate {
    enum Role {
        case phone, watch
        static var current: Self {
            #if os(watchOS)
            .watch
            #else
            .phone
            #endif
        }
    }

    @Published private(set) var status = "Connecting"
    @Published private(set) var lastSyncDate: Date?
    private let transport: any WatchConnectivityTransport
    private let role: Role
    private let persistence: UserDefaultsConfigurationPersistence
    private var state: ConfigurationSyncState
    private let onSnapshot: (ConfigurationSnapshot) -> Void
    private let logger = Logger(subsystem: "com.potomushto.AnyRing", category: "WatchSync")
    private var requesting = false
    private var started = false
    private var needsBackgroundTransfer = false

    init(persistence: UserDefaultsConfigurationPersistence,
         transport: any WatchConnectivityTransport = WCSessionTransport(),
         role: Role = .current,
         onSnapshot: @escaping (ConfigurationSnapshot) -> Void) {
        self.persistence = persistence
        self.transport = transport
        self.role = role
        self.onSnapshot = onSnapshot
        state = ConfigurationSyncState(latest: persistence.restoreSnapshot())
        lastSyncDate = persistence.restoreLastSyncDate()
        super.init()
    }

    /// Start only after the consumer is installed. The App owns this service for its lifetime.
    func start() {
        guard !started, transport.isSupported else { return }
        started = true
        if role == .phone {
            needsBackgroundTransfer = true
            persistence.persist(config: persistence.restore() ?? UserDefaultsConfigurationPersistence.defaultConfig)
            state = ConfigurationSyncState(latest: persistence.restoreSnapshot())
        }
        transport.configure(delegate: self)
        transport.activate()
        if transport.activationState == .activated { refresh() }
    }

    func publish(_ config: AnyRingConfig) {
        guard role == .phone else { return }
        persistence.persist(config: config)
        let latest = persistence.restoreSnapshot()
        if latest?.revision != state.latest?.revision { needsBackgroundTransfer = true }
        state = ConfigurationSyncState(latest: latest)
        sendLatest()
    }

    func refresh() {
        guard transport.isSupported else { status = "Watch sync unavailable"; return }
        guard transport.activationState == .activated else {
            transport.activate()
            return
        }
        if role == .watch {
            receiveCachedContext()
            requestLatest()
        } else { sendLatest() }
    }

    private func payload() -> [String: Any] {
        let legacyEncoder = JSONEncoder()
        legacyEncoder.userInfo[.legacyColorArchive] = true
        guard let snapshot = state.latest,
              let data = try? JSONEncoder().encode(snapshot),
              let config = try? legacyEncoder.encode(snapshot.config) else { return [:] }
        return ["snapshot": data, "config": config]
    }

    private func sendLatest() {
        guard role == .phone, transport.activationState == .activated else { return }
        guard transport.isPaired, transport.isWatchAppInstalled else { status = "Install AnyProgress on Apple Watch"; return }
        let current = payload()
        guard !current.isEmpty else { return }
        do {
            try transport.updateApplicationContext(current)
            if needsBackgroundTransfer {
                transport.queueBackgroundSnapshot(current)
                needsBackgroundTransfer = false
            }
            status = "Ready for Apple Watch"
            if transport.isReachable {
                transport.sendMessage(current, replyHandler: { [weak self] reply in
                    guard let revision = reply["acknowledgedRevision"] as? Double else { return }
                    Task { @MainActor in self?.recordAcknowledgement(revision: revision) }
                }, errorHandler: { [weak self] error in
                    Task { @MainActor in self?.report(error) }
                })
            }
        } catch { report(error) }
    }

    private func receiveCachedContext() {
        let context = transport.receivedApplicationContext
        accept(snapshotData: context["snapshot"] as? Data, legacyConfig: context["config"] as? Data, isCached: true)
    }

    private func requestLatest() {
        guard transport.activationState == .activated, !requesting else { return }
        guard transport.isReachable else { status = "iPhone unavailable · saved settings"; return }
        requesting = true
        status = "Syncing with iPhone"
        transport.sendMessage(["refresh": true], replyHandler: { [weak self] reply in
            let data = reply["snapshot"] as? Data
            let legacy = reply["config"] as? Data
            Task { @MainActor in
                guard let self else { return }
                self.requesting = false
                self.accept(snapshotData: data, legacyConfig: legacy)
                if data == nil && legacy == nil { self.status = "Open AnyProgress on iPhone to sync" }
            }
        }, errorHandler: { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                self.requesting = false
                self.receiveCachedContext()
                self.report(error)
            }
        })
    }

    func accept(snapshotData: Data?, legacyConfig: Data?, isCached: Bool = false, sendAcknowledgement: Bool = true) {
        guard role == .watch else { return }
        do {
            let snapshot: ConfigurationSnapshot
            if let snapshotData {
                snapshot = try JSONDecoder().decode(ConfigurationSnapshot.self, from: snapshotData)
                guard state.latest.map({ snapshot.revision >= $0.revision }) ?? true else { return }
                if state.receive(snapshot) { onSnapshot(snapshot) }
            } else if let legacyConfig, state.latest?.revision ?? 0 == 0 {
                snapshot = ConfigurationSnapshot(config: try JSONDecoder().decode(AnyRingConfig.self, from: legacyConfig), revision: 0)
                if snapshot.config != state.latest?.config {
                    state = ConfigurationSyncState(latest: snapshot)
                    onSnapshot(snapshot)
                }
            } else { return }
            if !isCached { markSynced() }
            status = "Settings synced"
            if sendAcknowledgement, transport.activationState == .activated, transport.isReachable, let latest = state.latest {
                transport.sendMessage(["acknowledgedRevision": latest.revision], replyHandler: nil, errorHandler: nil)
            }
        } catch { report(error) }
    }

    func recordAcknowledgement(revision: Double) {
        guard role == .phone, revision.isFinite, revision == state.latest?.revision else { return }
        markSynced()
        status = "Settings synced"
    }

    private func markSynced() {
        let date = Date()
        lastSyncDate = date
        persistence.persistLastSyncDate(date)
    }

    private func report(_ error: Error) {
        logger.error("Watch sync: \(error.localizedDescription)")
        status = role == .watch ? "Sync unavailable · saved settings" : "Waiting to sync with Apple Watch"
    }

    func activationCompleted(error: Error? = nil) {
        if let error { report(error); return }
        refresh()
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated || error != nil else { return }
        Task { @MainActor in self.activationCompleted(error: error) }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in self.refresh() }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        let data = applicationContext["snapshot"] as? Data
        let legacy = applicationContext["config"] as? Data
        Task { @MainActor in self.accept(snapshotData: data, legacyConfig: legacy) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        let data = message["snapshot"] as? Data
        let legacy = message["config"] as? Data
        let acknowledged = message["acknowledgedRevision"] as? Double
        Task { @MainActor in
            if let acknowledged { self.recordAcknowledgement(revision: acknowledged) }
            else { self.accept(snapshotData: data, legacyConfig: legacy) }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        let data = userInfo["snapshot"] as? Data
        let legacy = userInfo["config"] as? Data
        Task { @MainActor in self.accept(snapshotData: data, legacyConfig: legacy) }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        let callback = SendableCallback(replyHandler)
        let data = message["snapshot"] as? Data
        let legacy = message["config"] as? Data
        Task { @MainActor in
            if self.role == .watch {
                self.accept(snapshotData: data, legacyConfig: legacy, sendAcknowledgement: false)
                callback.call(self.state.latest.map { ["acknowledgedRevision": $0.revision] } ?? [:])
                return
            }
            self.state = ConfigurationSyncState(latest: self.persistence.restoreSnapshot())
            callback.call(self.payload())
        }
    }

    nonisolated func session(_ session: WCSession, didFinish userInfoTransfer: WCSessionUserInfoTransfer, error: Error?) {
        guard let data = userInfoTransfer.userInfo["snapshot"] as? Data else { return }
        Task { @MainActor in
            let failed = try? JSONDecoder().decode(ConfigurationSnapshot.self, from: data)
            guard let revision = failed?.revision, revision == self.state.latest?.revision else { return }
            if let error {
                self.needsBackgroundTransfer = true
                self.report(error)
            } else { self.recordAcknowledgement(revision: revision) }
        }
    }

    #if os(iOS)
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.needsBackgroundTransfer = true
            self.sendLatest()
        }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) { session.activate() }
    #endif
}
