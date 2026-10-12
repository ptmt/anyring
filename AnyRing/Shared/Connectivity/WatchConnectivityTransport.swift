import Foundation
import WatchConnectivity

@MainActor
protocol WatchConnectivityTransport: AnyObject {
    var isSupported: Bool { get }
    var activationState: WCSessionActivationState { get }
    var isReachable: Bool { get }
    var isWatchAppInstalled: Bool { get }
    var isPaired: Bool { get }
    var receivedApplicationContext: [String: Any] { get }
    func configure(delegate: any WCSessionDelegate)
    func activate()
    func updateApplicationContext(_ context: [String: Any]) throws
    func queueBackgroundSnapshot(_ payload: [String: Any])
    func sendMessage(_ message: [String: Any], replyHandler: (@Sendable ([String: Any]) -> Void)?,
                     errorHandler: (@Sendable (Error) -> Void)?)
}

@MainActor
final class WCSessionTransport: WatchConnectivityTransport {
    private let session: WCSession
    init(session: WCSession = .default) { self.session = session }
    var isSupported: Bool { WCSession.isSupported() }
    var activationState: WCSessionActivationState { session.activationState }
    var isReachable: Bool { session.isReachable }
    var receivedApplicationContext: [String: Any] { session.receivedApplicationContext }
    var isWatchAppInstalled: Bool {
        #if os(iOS)
        session.isWatchAppInstalled
        #else
        true
        #endif
    }
    var isPaired: Bool {
        #if os(iOS)
        session.isPaired
        #else
        true
        #endif
    }
    func configure(delegate: any WCSessionDelegate) { session.delegate = delegate }
    func activate() { session.activate() }
    func updateApplicationContext(_ context: [String: Any]) throws { try session.updateApplicationContext(context) }
    func queueBackgroundSnapshot(_ payload: [String: Any]) {
        #if os(iOS)
        let data = payload["snapshot"] as? Data
        let pending = session.outstandingUserInfoTransfers
        if pending.contains(where: { ($0.userInfo["snapshot"] as? Data) == data }) { return }
        // Only the newest settings matter. Preserve unrelated queued event transfers.
        pending.filter { $0.userInfo["snapshot"] != nil }.forEach { $0.cancel() }
        if session.isComplicationEnabled, session.remainingComplicationUserInfoTransfers > 0 {
            session.transferCurrentComplicationUserInfo(payload)
        } else {
            session.transferUserInfo(payload)
        }
        #endif
    }

    func sendMessage(_ message: [String: Any], replyHandler: (@Sendable ([String: Any]) -> Void)?,
                     errorHandler: (@Sendable (Error) -> Void)?) {
        session.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }
}
