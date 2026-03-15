//
//  WorkoutService.swift
//  FitPulse
//
//  Manages workout tracking and HealthKit workout syncing
//

import Foundation
import HealthKit

struct WorkoutTypeInfo {
    let type: WorkoutType
    let hkActivityType: HKWorkoutActivityType
    let category: WorkoutCategory
}

enum WorkoutCategory: String, CaseIterable {
    case cardio = "Cardio"
    case strength = "Strength"
    case flexibility = "Flexibility"
    case sports = "Sports"
    case water = "Water"
    case other = "Other"
}

struct WorkoutStats {
    var totalWorkouts: Int
    var totalDuration: Double
    var totalCalories: Double
    var totalDistance: Double
    var averageDuration: Double
    var thisWeekWorkouts: Int
    var thisMonthWorkouts: Int

    static var empty: WorkoutStats {
        WorkoutStats(
            totalWorkouts: 0,
            totalDuration: 0,
            totalCalories: 0,
            totalDistance: 0,
            averageDuration: 0,
            thisWeekWorkouts: 0,
            thisMonthWorkouts: 0
        )
    }
}

final class WorkoutService {
    static let shared = WorkoutService()
    private init() {}

    // MARK: - Calorie Calculation
    func calculateCalories(
        workoutType: WorkoutType,
        durationSeconds: Double,
        weightKg: Double = 70.0
    ) -> Double {
        let durationMinutes = durationSeconds / 60
        let met = workoutType.metValue
        return (met * weightKg * (durationMinutes / 60)) * 1.05
    }

    // MARK: - Stats Calculation
    func calculateStats(from workouts: [Workout]) -> WorkoutStats {
        guard !workouts.isEmpty else { return .empty }

        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!

        let totalWorkouts = workouts.count
        let totalDuration = workouts.reduce(0) { $0 + $1.durationSeconds }
        let totalCalories = workouts.reduce(0) { $0 + $1.caloriesBurned }
        let totalDistance = workouts.compactMap { $0.distanceMeters }.reduce(0, +)
        let averageDuration = totalDuration / Double(totalWorkouts)
        let thisWeekWorkouts = workouts.filter { $0.startDate >= weekStart }.count
        let thisMonthWorkouts = workouts.filter { $0.startDate >= monthStart }.count

        return WorkoutStats(
            totalWorkouts: totalWorkouts,
            totalDuration: totalDuration,
            totalCalories: totalCalories,
            totalDistance: totalDistance,
            averageDuration: averageDuration,
            thisWeekWorkouts: thisWeekWorkouts,
            thisMonthWorkouts: thisMonthWorkouts
        )
    }

    // MARK: - HK Activity Type Mapping
    func hkActivityType(for workoutType: WorkoutType) -> HKWorkoutActivityType {
        switch workoutType {
        case .running: return .running
        case .cycling: return .cycling
        case .swimming: return .swimming
        case .strengthTraining: return .traditionalStrengthTraining
        case .yoga: return .yoga
        case .hiking: return .hiking
        case .walking: return .walking
        case .elliptical: return .elliptical
        case .rowing: return .rowing
        case .pilates: return .pilates
        case .basketball: return .basketball
        case .soccer: return .soccer
        case .tennis: return .tennis
        case .other: return .other
        }
    }

    // MARK: - All Workout Types with Extended Info
    var allWorkoutTypes: [WorkoutTypeInfo] {
        WorkoutType.allCases.map { type in
            WorkoutTypeInfo(
                type: type,
                hkActivityType: hkActivityType(for: type),
                category: category(for: type)
            )
        }
    }

    func category(for type: WorkoutType) -> WorkoutCategory {
        switch type {
        case .running, .cycling, .walking, .hiking, .elliptical, .rowing: return .cardio
        case .strengthTraining: return .strength
        case .yoga, .pilates: return .flexibility
        case .basketball, .soccer, .tennis: return .sports
        case .swimming: return .water
        case .other: return .other
        }
    }

    // MARK: - Export
    func exportCSV(workouts: [Workout]) -> String {
        var csv = "Date,Type,Duration (min),Calories,Distance (km),Avg HR,Notes\n"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"

        for workout in workouts {
            let date = formatter.string(from: workout.startDate)
            let type = workout.workoutType
            let duration = String(format: "%.1f", workout.durationSeconds / 60)
            let calories = String(format: "%.0f", workout.caloriesBurned)
            let distance = workout.distanceMeters.map { String(format: "%.2f", $0 / 1000) } ?? ""
            let hr = workout.averageHeartRate.map { String(format: "%.0f", $0) } ?? ""
            let notes = workout.notes ?? ""
            csv += "\(date),\(type),\(duration),\(calories),\(distance),\(hr),\(notes)\n"
        }
        return csv
    }
}
