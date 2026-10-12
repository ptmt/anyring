//
//  Progress.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation

struct Progress: CustomStringConvertible, Sendable {
    
    let absolute: Double
    let maxAbsolute: Double
    let minAbsolute: Double
    var reversed: Bool = false
    
    private var normMin: Double {
        0
    }
    private var normMax: Double {
        precondition(maxAbsolute - minAbsolute != 0)
        return maxAbsolute - minAbsolute
    }
    
    var normalized: Double {
        (!absolute.isFinite || !minAbsolute.isFinite || !maxAbsolute.isFinite || minAbsolute >= maxAbsolute) ? 0 : max(0, reversed ? (maxAbsolute - absolute) / normMax : (absolute - minAbsolute) / normMax)
    }
    
    var description: String {
        return "\((absolute).IntOrString)/\((reversed ? (minAbsolute) : (maxAbsolute)).IntOrString)"
    }
    
    static let Empty = Progress(absolute: 0, maxAbsolute: 100, minAbsolute: 0)
    
    var empty: Bool {
        absolute == normMin
    }
}

extension Double {
    var IntOrString: String {
        if self >= Double(Int.min) && self < Double(Int.max) {
            return String(Int(self))
        } else {
            return String(self)
        }
    }
}
