//
//  SleepSession.swift
//  FitPulse
//

import Foundation
import SwiftData

enum SleepStage: String, Codable, CaseIterable {
    case awake = "Awake"
    case rem = "REM"
    case core = "Core"
    case deep = "Deep"
    case unknown = "Unknown"

    var color: String {
        switch self {
        case .awake: return "red"
        case .rem: return "purple"
        case .core: return "blue"
        case .deep: return "indigo"
        case .unknown: return "gray"
        }
    }
}

@Model
final class SleepSession {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var totalMinutes: Double
    var deepSleepMinutes: Double
    var remSleepMinutes: Double
    var coreSleepMinutes: Double
    var awakeMinutes: Double
    var sleepQualityScore: Int?
    var notes: String?

    init(
        startDate: Date,
        endDate: Date,
        totalMinutes: Double,
        deepSleepMinutes: Double = 0,
        remSleepMinutes: Double = 0,
        coreSleepMinutes: Double = 0,
        awakeMinutes: Double = 0,
        sleepQualityScore: Int? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.totalMinutes = totalMinutes
        self.deepSleepMinutes = deepSleepMinutes
        self.remSleepMinutes = remSleepMinutes
        self.coreSleepMinutes = coreSleepMinutes
        self.awakeMinutes = awakeMinutes
        self.sleepQualityScore = sleepQualityScore
        self.notes = notes
    }

    var durationFormatted: String {
        let hours = Int(totalMinutes) / 60
        let mins = Int(totalMinutes) % 60
        return "\(hours)h \(mins)m"
    }

    var sleepEfficiency: Double {
        guard totalMinutes > 0 else { return 0 }
        let sleepTime = totalMinutes - awakeMinutes
        return (sleepTime / totalMinutes) * 100
    }

    var qualityLabel: String {
        guard let score = sleepQualityScore else {
            let efficiency = sleepEfficiency
            switch efficiency {
            case 90...: return "Excellent"
            case 75..<90: return "Good"
            case 60..<75: return "Fair"
            default: return "Poor"
            }
        }
        switch score {
        case 80...: return "Excellent"
        case 60..<80: return "Good"
        case 40..<60: return "Fair"
        default: return "Poor"
        }
    }
}
