//
//  Workout.swift
//  FitPulse
//

import Foundation
import SwiftData

enum WorkoutType: String, Codable, CaseIterable {
    case running = "Running"
    case cycling = "Cycling"
    case swimming = "Swimming"
    case strengthTraining = "Strength Training"
    case yoga = "Yoga"
    case hiking = "Hiking"
    case walking = "Walking"
    case elliptical = "Elliptical"
    case rowing = "Rowing"
    case pilates = "Pilates"
    case basketball = "Basketball"
    case soccer = "Soccer"
    case tennis = "Tennis"
    case other = "Other"

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .cycling: return "figure.outdoor.cycle"
        case .swimming: return "figure.pool.swim"
        case .strengthTraining: return "dumbbell.fill"
        case .yoga: return "figure.yoga"
        case .hiking: return "figure.hiking"
        case .walking: return "figure.walk"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rowing"
        case .pilates: return "figure.pilates"
        case .basketball: return "sportscourt.fill"
        case .soccer: return "soccerball"
        case .tennis: return "tennisball.fill"
        case .other: return "figure.mixed.cardio"
        }
    }

    var color: String {
        switch self {
        case .running: return "green"
        case .cycling: return "blue"
        case .swimming: return "cyan"
        case .strengthTraining: return "orange"
        case .yoga: return "purple"
        case .hiking: return "brown"
        case .walking: return "mint"
        case .elliptical: return "indigo"
        case .rowing: return "teal"
        case .pilates: return "pink"
        case .basketball, .soccer, .tennis: return "red"
        case .other: return "gray"
        }
    }

    var metValue: Double {
        switch self {
        case .running: return 9.8
        case .cycling: return 7.5
        case .swimming: return 8.0
        case .strengthTraining: return 5.0
        case .yoga: return 3.0
        case .hiking: return 6.0
        case .walking: return 3.5
        case .elliptical: return 5.0
        case .rowing: return 7.0
        case .pilates: return 3.5
        case .basketball: return 8.0
        case .soccer: return 7.0
        case .tennis: return 7.3
        case .other: return 5.0
        }
    }
}

@Model
final class Workout {
    var id: UUID
    var workoutType: String
    var startDate: Date
    var endDate: Date
    var durationSeconds: Double
    var distanceMeters: Double?
    var caloriesBurned: Double
    var averageHeartRate: Double?
    var maxHeartRate: Double?
    var steps: Int?
    var notes: String?
    var sourceIdentifier: String

    init(
        workoutType: WorkoutType,
        startDate: Date,
        endDate: Date,
        durationSeconds: Double,
        distanceMeters: Double? = nil,
        caloriesBurned: Double,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        steps: Int? = nil,
        notes: String? = nil,
        sourceIdentifier: String = "fitpulse"
    ) {
        self.id = UUID()
        self.workoutType = workoutType.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.durationSeconds = durationSeconds
        self.distanceMeters = distanceMeters
        self.caloriesBurned = caloriesBurned
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.steps = steps
        self.notes = notes
        self.sourceIdentifier = sourceIdentifier
    }

    var workoutTypeEnum: WorkoutType {
        WorkoutType(rawValue: workoutType) ?? .other
    }

    var durationFormatted: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        let seconds = Int(durationSeconds) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }

    var distanceFormatted: String? {
        guard let distance = distanceMeters else { return nil }
        let km = distance / 1000
        if km >= 1.0 {
            return String(format: "%.2f km", km)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
}
