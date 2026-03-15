//
//  WorkoutViewModel.swift
//  FitPulse
//
//  Manages workout logging and history
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class WorkoutViewModel {

    private var healthKitService: HealthKitService

    var isLoading = false
    var errorMessage: String?
    var showAddWorkout = false
    var showPaywall = false
    var selectedFilter: WorkoutType? = nil
    var searchText = ""

    var stats: WorkoutStats = .empty

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Filtered Workouts

    func filteredWorkouts(_ workouts: [Workout]) -> [Workout] {
        var result = workouts

        if let filter = selectedFilter {
            result = result.filter { $0.workoutTypeEnum == filter }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.workoutType.localizedCaseInsensitiveContains(searchText) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        return result.sorted { $0.startDate > $1.startDate }
    }

    // MARK: - Add Workout

    func addWorkout(
        type: WorkoutType,
        date: Date,
        durationMinutes: Double,
        distanceKm: Double?,
        calories: Double?,
        averageHR: Double?,
        notes: String?,
        context: ModelContext,
        weightKg: Double = 70.0
    ) async {
        let durationSeconds = durationMinutes * 60
        let distanceMeters = distanceKm.map { $0 * 1000 }
        let computedCalories = calories ?? WorkoutService.shared.calculateCalories(
            workoutType: type,
            durationSeconds: durationSeconds,
            weightKg: weightKg
        )

        let start = date
        let end = Calendar.current.date(byAdding: .second, value: Int(durationSeconds), to: start)!

        let workout = Workout(
            workoutType: type,
            startDate: start,
            endDate: end,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            caloriesBurned: computedCalories,
            averageHeartRate: averageHR,
            notes: notes
        )

        context.insert(workout)

        // Save to HealthKit
        if healthKitService.isAuthorized {
            try? await healthKitService.saveWorkout(
                type: WorkoutService.shared.hkActivityType(for: type),
                start: start,
                end: end,
                calories: computedCalories,
                distance: distanceMeters
            )
        }

        AnalyticsService.shared.track(.workoutLogged(type: type.rawValue))
    }

    func deleteWorkout(_ workout: Workout, context: ModelContext) {
        context.delete(workout)
        AnalyticsService.shared.track(.workoutDeleted)
    }

    // MARK: - Stats

    func updateStats(from workouts: [Workout]) {
        stats = WorkoutService.shared.calculateStats(from: workouts)
    }

    // MARK: - Recent Workouts

    func recentWorkouts(_ workouts: [Workout], limit: Int = 5) -> [Workout] {
        Array(workouts.sorted { $0.startDate > $1.startDate }.prefix(limit))
    }

    // MARK: - Export

    func exportCSV(workouts: [Workout]) -> String {
        WorkoutService.shared.exportCSV(workouts: workouts)
    }
}
