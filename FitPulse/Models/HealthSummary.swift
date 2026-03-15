//
//  HealthSummary.swift
//  FitPulse
//

import Foundation
import SwiftData

struct HealthSummary {
    var date: Date
    var steps: Int
    var distanceMeters: Double
    var activeCalories: Double
    var restingCalories: Double
    var exerciseMinutes: Double
    var standHours: Double
    var averageHeartRate: Double?
    var restingHeartRate: Double?
    var sleepHours: Double?

    var totalCalories: Double {
        activeCalories + restingCalories
    }

    var distanceKm: Double {
        distanceMeters / 1000
    }

    static var empty: HealthSummary {
        HealthSummary(
            date: Date(),
            steps: 0,
            distanceMeters: 0,
            activeCalories: 0,
            restingCalories: 0,
            exerciseMinutes: 0,
            standHours: 0,
            averageHeartRate: nil,
            restingHeartRate: nil,
            sleepHours: nil
        )
    }
}

@Model
final class UserGoal {
    var id: UUID
    var dailyStepGoal: Int
    var dailyCalorieGoal: Double
    var dailyExerciseMinutes: Double
    var dailyStandHours: Double
    var weeklyWorkoutGoal: Int
    var weightGoal: Double?
    var createdAt: Date
    var updatedAt: Date

    init(
        dailyStepGoal: Int = 10000,
        dailyCalorieGoal: Double = 500,
        dailyExerciseMinutes: Double = 30,
        dailyStandHours: Double = 12,
        weeklyWorkoutGoal: Int = 5,
        weightGoal: Double? = nil
    ) {
        self.id = UUID()
        self.dailyStepGoal = dailyStepGoal
        self.dailyCalorieGoal = dailyCalorieGoal
        self.dailyExerciseMinutes = dailyExerciseMinutes
        self.dailyStandHours = dailyStandHours
        self.weeklyWorkoutGoal = weeklyWorkoutGoal
        self.weightGoal = weightGoal
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
