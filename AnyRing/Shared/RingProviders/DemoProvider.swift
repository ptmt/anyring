//
//  DemoProvider.swift
//  AnyRing
//
//  Created by Dmitriy Loktev on 20.12.2020.
//

import Foundation
import Combine
import HealthKit
import SwiftUI

class DemoProvider: RingProvider {
    
    struct Configuration: ProviderConfiguration {
        var provider: RingProvider.Type { DemoProvider.self }
        
        var minValue: Double
        var maxValue: Double
        var mainColor: CodableColor
    }
    
    var units: String = "KCAL"
    var name: String = "Demo"
    let description: String = "Demo provider"
    let config: ProviderConfiguration
    
    private let initValue: Double
    
    required init(dataSource: HealthKitDataSource, config: ProviderConfiguration) {
        self.initValue = 20
        self.config = config
    }
    
    init(_ name: String = "Demo", initValue: Double = 20, units: String = "KCAL", config: Configuration = Configuration(minValue: 0, maxValue: 100, mainColor: CodableColor(.orange))) {
        self.name = name
        self.initValue = initValue
        self.units = units
        self.config = config
    }
    
    func viewModel() -> RingViewModel {
        RingViewModel(provider: self)
    }
    
    func requestNeededPermissions() -> Future<Bool, Error> {
        return Future() { promise in
            promise(.success(true))
        }
    }
    
    func calculateProgress() -> AnyPublisher<Progress, Error> {
        Result<Progress, Error>.Publisher(.success(Progress(absolute: initValue, maxAbsolute: config.maxValue, minAbsolute: config.minValue))).eraseToAnyPublisher()
    }
    
    var requiredHKPermission: HKSampleType? = nil
}

//struct CodableColor: Codable {
//    var red: Double
//    var green: Double
//    var blue: Double
//    var opacity: Double
//
//    init(_ color: Color) {
//        self.red = color.cgColor!.components
//    }
//    //private var cachedColor: Color?
//    var color: Color {
//       Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
//    }
//}

struct CodableColor: Codable {
    let color: Color
    init(_ color: Color) {
        self.color = color
    }

    enum CodingKeys: String, CodingKey {
        case color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let data = try container.decode(Data.self)
        if let uiColor = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? UIColor {
            self.color = Color(uiColor)
        } else {
            self.color = Color.red // fail silently
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let uiColor = UIColor(color)
        let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
        try container.encode(colorData)
    }
}
