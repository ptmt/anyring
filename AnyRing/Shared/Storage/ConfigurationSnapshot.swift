import Foundation

struct ConfigurationSnapshot: Codable, Sendable {
    let config: AnyRingConfig
    /// iPhone-issued monotonic timestamp. The Watch never issues revisions.
    let revision: TimeInterval

    init(config: AnyRingConfig, revision: TimeInterval) {
        self.config = config
        self.revision = revision
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        config = try values.decode(AnyRingConfig.self, forKey: .config)
        revision = try values.decode(TimeInterval.self, forKey: .revision)
        guard revision.isFinite, revision >= 0 else {
            throw DecodingError.dataCorruptedError(forKey: .revision, in: values,
                                                   debugDescription: "Invalid sync revision")
        }
    }

    enum CodingKeys: String, CodingKey { case config, revision }
}

/// Transport-independent ordering, used by every incoming WatchConnectivity channel.
struct ConfigurationSyncState: Sendable {
    private(set) var latest: ConfigurationSnapshot?

    init(latest: ConfigurationSnapshot? = nil) { self.latest = latest }

    @discardableResult
    mutating func receive(_ snapshot: ConfigurationSnapshot) -> Bool {
        guard snapshot.revision.isFinite, snapshot.revision >= 0,
              latest.map({ snapshot.revision > $0.revision }) ?? true else { return false }
        latest = snapshot
        return true
    }
}
