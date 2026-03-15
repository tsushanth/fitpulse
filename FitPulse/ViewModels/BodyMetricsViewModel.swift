//
//  BodyMetricsViewModel.swift
//  FitPulse
//
//  Manages body metrics tracking and trends
//

import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class BodyMetricsViewModel {

    private var healthKitService: HealthKitService

    var isLoading = false
    var errorMessage: String?
    var showAddMetric = false
    var showPaywall = false
    var selectedMetricType: BodyMetricType = .weight

    var latestWeight: Double? = nil
    var latestBodyFat: Double? = nil
    var latestBMI: Double? = nil
    var height: Double? = nil

    init(healthKitService: HealthKitService) {
        self.healthKitService = healthKitService
    }

    // MARK: - Computed BMI

    func calculateBMI(weight: Double, heightM: Double) -> Double {
        guard heightM > 0 else { return 0 }
        return weight / (heightM * heightM)
    }

    var bmiCategory: BMICategory? {
        guard let bmi = latestBMI else { return nil }
        return BMICategory(value: bmi)
    }

    // MARK: - Filtered Metrics

    func metrics(for type: BodyMetricType, from allMetrics: [BodyMetric]) -> [BodyMetric] {
        allMetrics
            .filter { $0.metricTypeEnum == type }
            .sorted { $0.date > $1.date }
    }

    func latestMetric(for type: BodyMetricType, from allMetrics: [BodyMetric]) -> BodyMetric? {
        metrics(for: type, from: allMetrics).first
    }

    // MARK: - Trend Calculation

    func trend(for type: BodyMetricType, from allMetrics: [BodyMetric]) -> TrendDirection {
        let filtered = metrics(for: type, from: allMetrics)
        guard filtered.count >= 2 else { return .stable }
        let latest = filtered[0].value
        let previous = filtered[1].value
        let diff = latest - previous

        switch type {
        case .weight, .bodyFat, .bmi:
            if diff > 0.5 { return .up }
            if diff < -0.5 { return .down }
            return .stable
        default:
            if diff > 0 { return .up }
            if diff < 0 { return .down }
            return .stable
        }
    }

    func trendValue(for type: BodyMetricType, from allMetrics: [BodyMetric]) -> String {
        let filtered = metrics(for: type, from: allMetrics)
        guard filtered.count >= 2 else { return "No data" }
        let diff = filtered[0].value - filtered[1].value
        let sign = diff >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", diff)) \(type.unit)"
    }

    // MARK: - Chart Data

    func chartData(for type: BodyMetricType, from allMetrics: [BodyMetric], days: Int = 30) -> [(Date, Double)] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return metrics(for: type, from: allMetrics)
            .filter { $0.date >= cutoff }
            .reversed()
            .map { ($0.date, $0.value) }
    }

    // MARK: - Save Metrics

    func addMetric(
        type: BodyMetricType,
        value: Double,
        date: Date,
        notes: String?,
        context: ModelContext
    ) async {
        let metric = BodyMetric(metricType: type, value: value, date: date, notes: notes)
        context.insert(metric)

        // Sync to HealthKit
        if healthKitService.isAuthorized {
            do {
                switch type {
                case .weight:
                    try await healthKitService.saveWeight(value, date: date)
                    latestWeight = value
                    if let h = height {
                        latestBMI = calculateBMI(weight: value, heightM: h)
                    }
                case .bodyFat:
                    try await healthKitService.saveBodyFat(value, date: date)
                    latestBodyFat = value
                default:
                    break
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }

        AnalyticsService.shared.track(.bodyMetricLogged(type: type.rawValue))
    }

    func deleteMetric(_ metric: BodyMetric, context: ModelContext) {
        context.delete(metric)
    }

    // MARK: - Load Data

    func loadHealthKitData() async {
        latestWeight = healthKitService.latestWeight
        latestBodyFat = healthKitService.latestBodyFat
    }
}

enum TrendDirection {
    case up, down, stable

    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .up: return .fitPulseRed
        case .down: return .fitPulseGreen
        case .stable: return .gray
        }
    }
}

import SwiftUI
