//
//  ReportsViewModel.swift
//  FitPulse
//
//  Weekly and monthly activity reports
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class ReportsViewModel {

    private var healthKitService: HealthKitService

    var isLoading = false
    var errorMessage: String?
    var selectedPeriod: ReportPeriod = .week
    var showPaywall = false

    // Weekly Summary
    var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    var weeklyCalories: [Double] = Array(repeating: 0, count: 7)
    var weeklyExercise: [Double] = Array(repeating: 0, count: 7)
    var weeklyWorkouts: Int = 0
    var averageSleepHours: Double = 0

    // Monthly Summary
    var monthlySteps: Int = 0
    var monthlyCalories: Double = 0
    var monthlyWorkouts: Int = 0
    var bestDay: String = ""

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Load Reports

    func loadReports(workouts: [Workout]) async {
        isLoading = true

        weeklySteps = healthKitService.weeklySteps
        weeklyCalories = healthKitService.weeklyCalories
        weeklyExercise = healthKitService.weeklyExercise

        await loadMonthlyData(workouts: workouts)

        isLoading = false
        AnalyticsService.shared.track(.reportViewed)
    }

    private func loadMonthlyData(workouts: [Workout]) async {
        let calendar = Calendar.current
        let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        let monthWorkouts = workouts.filter { $0.startDate >= monthStart }
        monthlyWorkouts = monthWorkouts.count
        monthlyCalories = monthWorkouts.reduce(0) { $0 + $1.caloriesBurned }
        monthlySteps = weeklySteps.reduce(0, +) * 4 // Estimate

        weeklyWorkouts = countWeeklyWorkouts(workouts: workouts)

        // Find best day
        let maxIdx = weeklySteps.enumerated().max(by: { $0.element < $1.element })?.offset ?? 0
        let calendar2 = Calendar.current
        if let day = calendar2.date(byAdding: .day, value: -(6 - maxIdx), to: Date()) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            bestDay = formatter.string(from: day)
        }
    }

    private func countWeeklyWorkouts(workouts: [Workout]) -> Int {
        let calendar = Calendar.current
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return workouts.filter { $0.startDate >= weekStart }.count
    }

    // MARK: - Summary Cards

    var weeklySummaryCards: [SummaryCard] {
        [
            SummaryCard(
                title: "Total Steps",
                value: weeklySteps.reduce(0, +).formatted(),
                subtitle: "This week",
                icon: "figure.walk",
                color: .fitPulseGreen
            ),
            SummaryCard(
                title: "Active Calories",
                value: "\(Int(weeklyCalories.reduce(0, +)))",
                subtitle: "kcal burned",
                icon: "flame.fill",
                color: .fitPulseRed
            ),
            SummaryCard(
                title: "Exercise Time",
                value: "\(Int(weeklyExercise.reduce(0, +))) min",
                subtitle: "active minutes",
                icon: "bolt.fill",
                color: .fitPulseOrange
            ),
            SummaryCard(
                title: "Workouts",
                value: "\(weeklyWorkouts)",
                subtitle: "completed",
                icon: "figure.run",
                color: .fitPulseBlue
            ),
        ]
    }

    // MARK: - Day Labels

    var dayLabels: [String] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: Date())!
            return formatter.string(from: date)
        }
    }

    // MARK: - Export

    func generateReport(workouts: [Workout]) -> String {
        var report = "FitPulse Weekly Report\n"
        report += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n\n"
        report += "=== This Week ===\n"
        report += "Total Steps: \(weeklySteps.reduce(0, +).formatted())\n"
        report += "Active Calories: \(Int(weeklyCalories.reduce(0, +))) kcal\n"
        report += "Exercise Time: \(Int(weeklyExercise.reduce(0, +))) minutes\n"
        report += "Workouts Completed: \(weeklyWorkouts)\n\n"
        report += "=== Workouts ===\n"
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let weekWorkouts = workouts.filter { $0.startDate >= weekStart }
        for w in weekWorkouts {
            report += "• \(w.workoutType) - \(w.durationFormatted) - \(Int(w.caloriesBurned)) kcal\n"
        }
        return report
    }
}

enum ReportPeriod: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
}

struct SummaryCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
}

import SwiftUI
