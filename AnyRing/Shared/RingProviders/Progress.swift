//
//  Progress.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 21.12.2020.
//

import Foundation

struct Progress: CustomStringConvertible {
    
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
        (absolute.isNaN || minAbsolute >= maxAbsolute) ? 0 : (reversed ? (maxAbsolute - absolute) / normMax : absolute / normMax)
    }
    
    var description: String {
        return "\((absolute))/\(reversed ? (minAbsolute) : (maxAbsolute))"
    }
    
    static let Empty = Progress(absolute: 0, maxAbsolute: 100, minAbsolute: 0)
    
    var empty: Bool {
        absolute == normMin
    }
}
