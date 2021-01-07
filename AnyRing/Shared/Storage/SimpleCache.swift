//
//  SimpleCache.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 07.01.2021.
//

import Foundation

class SimpleCache {
    static let key = "cache"
    private let storage = UserDefaults(suiteName: "group.49PJNAT2WC.com.potomushto.AnyRing")!
    func restoreLastSnapshot() -> RingWrapper<RingSnapshot>? {
        if let json = storage.value(forKey: SimpleCache.key) as? Data, let decoded = try? JSONDecoder().decode([RingSnapshot].self, from: json) {
            return RingWrapper(decoded)
        } else {
            return nil
        }
    }
    func store(lastSnapshot: RingWrapper<RingSnapshot>?) {
        if let list = lastSnapshot?.list,
           let json = try? JSONEncoder().encode(list) {
            storage.setValue(json, forKey: SimpleCache.key)
        }
    }
}
