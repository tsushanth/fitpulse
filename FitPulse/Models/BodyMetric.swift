//
//  BodyMetric.swift
//  FitPulse
//

import Foundation
import SwiftData

enum BodyMetricType: String, Codable, CaseIterable {
    case weight = "Weight"
    case bodyFat = "Body Fat"
    case bmi = "BMI"
    case muscleMass = "Muscle Mass"
    case boneMass = "Bone Mass"
    case waterPercentage = "Water %"

    var unit: String {
        switch self {
        case .weight: return "kg"
        case .bodyFat: return "%"
        case .bmi: return "BMI"
        case .muscleMass: return "kg"
        case .boneMass: return "kg"
        case .waterPercentage: return "%"
        }
    }

    var icon: String {
        switch self {
        case .weight: return "scalemass.fill"
        case .bodyFat: return "percent"
        case .bmi: return "figure.stand"
        case .muscleMass: return "figure.strengthtraining.traditional"
        case .boneMass: return "staroflife.fill"
        case .waterPercentage: return "drop.fill"
        }
    }
}

@Model
final class BodyMetric {
    var id: UUID
    var metricType: String
    var value: Double
    var date: Date
    var notes: String?

    init(metricType: BodyMetricType, value: Double, date: Date = Date(), notes: String? = nil) {
        self.id = UUID()
        self.metricType = metricType.rawValue
        self.value = value
        self.date = date
        self.notes = notes
    }

    var metricTypeEnum: BodyMetricType {
        BodyMetricType(rawValue: metricType) ?? .weight
    }

    var formattedValue: String {
        let type = metricTypeEnum
        switch type {
        case .weight, .muscleMass, .boneMass:
            return String(format: "%.1f %@", value, type.unit)
        case .bodyFat, .waterPercentage:
            return String(format: "%.1f%@", value, type.unit)
        case .bmi:
            return String(format: "%.1f", value)
        }
    }
}

struct BMICategory {
    let value: Double

    var category: String {
        switch value {
        case ..<18.5: return "Underweight"
        case 18.5..<25.0: return "Normal"
        case 25.0..<30.0: return "Overweight"
        default: return "Obese"
        }
    }

    var color: String {
        switch value {
        case ..<18.5: return "blue"
        case 18.5..<25.0: return "green"
        case 25.0..<30.0: return "orange"
        default: return "red"
        }
    }
}
