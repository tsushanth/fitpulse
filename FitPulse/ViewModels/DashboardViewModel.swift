//
//  DashboardViewModel.swift
//  FitPulse
//
//  Dashboard / Home screen view model
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - Dependencies
    private var healthKitService: HealthKitService

    // MARK: - State
    var isLoading = false
    var errorMessage: String?
    var showPaywall = false

    // MARK: - Today's Activity
    var steps: Int = 0
    var distanceMeters: Double = 0
    var activeCalories: Double = 0
    var exerciseMinutes: Double = 0
    var standHours: Double = 0
    var currentHeartRate: Double? = nil
    var restingHeartRate: Double? = nil

    // MARK: - Goals
    var stepGoal: Int = 10000
    var calorieGoal: Double = 500
    var exerciseGoal: Double = 30
    var standGoal: Double = 12

    // MARK: - Rings
    var activityRings: ActivityRings = .empty

    // MARK: - Weekly
    var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    var weeklyCalories: [Double] = Array(repeating: 0, count: 7)

    // MARK: - Body
    var latestWeight: Double? = nil
    var latestBodyFat: Double? = nil

    // MARK: - Greeting
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    var stepsProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return min(Double(steps) / Double(stepGoal), 1.0)
    }

    var stepsPercentage: Int {
        Int(stepsProgress * 100)
    }

    var distanceKm: Double {
        distanceMeters / 1000
    }

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Actions

    func loadData(goals: UserGoal?) async {
        isLoading = true

        if let goals = goals {
            stepGoal = goals.dailyStepGoal
            calorieGoal = goals.dailyCalorieGoal
            exerciseGoal = goals.dailyExerciseMinutes
            standGoal = goals.dailyStandHours
        }

        await healthKitService.fetchAllTodayData()
        updateFromHealthKit()

        isLoading = false
    }

    func refresh() async {
        await healthKitService.refreshData()
        updateFromHealthKit()
    }

    private func updateFromHealthKit() {
        steps = healthKitService.todaySteps
        distanceMeters = healthKitService.todayDistance
        activeCalories = healthKitService.todayActiveCalories
        exerciseMinutes = healthKitService.todayExerciseMinutes
        standHours = healthKitService.todayStandHours
        currentHeartRate = healthKitService.currentHeartRate
        restingHeartRate = healthKitService.restingHeartRate
        latestWeight = healthKitService.latestWeight
        latestBodyFat = healthKitService.latestBodyFat
        weeklySteps = healthKitService.weeklySteps
        weeklyCalories = healthKitService.weeklyCalories

        activityRings = ActivityRingCalculator.shared.calculateRings(
            activeCalories: activeCalories,
            moveGoal: calorieGoal,
            exerciseMinutes: exerciseMinutes,
            exerciseGoal: exerciseGoal,
            standHours: standHours,
            standGoal: standGoal
        )
    }

    func requestHealthKitAccess() async {
        await healthKitService.requestAuthorization()
        AnalyticsService.shared.track(.healthKitConnected)
    }

    // MARK: - Stat Cards
    var statCards: [StatCard] {
        [
            StatCard(
                title: "Steps",
                value: steps.formatted(),
                subtitle: "\(Int(distanceKm * 10) / 10) km",
                icon: "figure.walk",
                color: .fitPulseGreen,
                progress: stepsProgress
            ),
            StatCard(
                title: "Active Cal",
                value: "\(Int(activeCalories))",
                subtitle: "kcal burned",
                icon: "flame.fill",
                color: .fitPulseRed,
                progress: min(activeCalories / calorieGoal, 1.0)
            ),
            StatCard(
                title: "Exercise",
                value: "\(Int(exerciseMinutes))",
                subtitle: "minutes",
                icon: "bolt.fill",
                color: .fitPulseOrange,
                progress: min(exerciseMinutes / exerciseGoal, 1.0)
            ),
            StatCard(
                title: "Stand",
                value: "\(Int(standHours))",
                subtitle: "hours",
                icon: "figure.stand",
                color: .fitPulseBlue,
                progress: min(standHours / standGoal, 1.0)
            ),
        ]
    }
}

struct StatCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    let progress: Double
}

import SwiftUI
