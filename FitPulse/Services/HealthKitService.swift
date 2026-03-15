//
//  HealthKitService.swift
//  FitPulse
//
//  Comprehensive HealthKit integration for health and fitness data
//

import Foundation
import HealthKit
import Observation

@MainActor
@Observable
final class HealthKitService {
    // MARK: - Properties
    private let healthStore = HKHealthStore()

    private(set) var isAuthorized = false
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    // Today's data
    private(set) var todaySteps: Int = 0
    private(set) var todayDistance: Double = 0
    private(set) var todayActiveCalories: Double = 0
    private(set) var todayRestingCalories: Double = 0
    private(set) var todayExerciseMinutes: Double = 0
    private(set) var todayStandHours: Double = 0
    private(set) var currentHeartRate: Double? = nil
    private(set) var restingHeartRate: Double? = nil
    private(set) var latestWeight: Double? = nil
    private(set) var latestBodyFat: Double? = nil

    // Weekly summary
    private(set) var weeklySteps: [Int] = Array(repeating: 0, count: 7)
    private(set) var weeklyCalories: [Double] = Array(repeating: 0, count: 7)
    private(set) var weeklyExercise: [Double] = Array(repeating: 0, count: 7)

    // MARK: - HealthKit Types
    private var typesToRead: Set<HKObjectType> {
        Set([
            HKQuantityType(.stepCount),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.basalEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKQuantityType(.appleStandTime),
            HKQuantityType(.heartRate),
            HKQuantityType(.restingHeartRate),
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKQuantityType(.bodyMassIndex),
            HKQuantityType(.height),
            HKQuantityType(.oxygenSaturation),
            HKCategoryType(.sleepAnalysis),
            HKObjectType.workoutType(),
        ])
    }

    private var typesToShare: Set<HKSampleType> {
        Set([
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass),
            HKQuantityType(.bodyFatPercentage),
            HKCategoryType(.sleepAnalysis),
            HKObjectType.workoutType(),
        ])
    }

    // MARK: - Authorization

    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isHealthKitAvailable else {
            errorMessage = "HealthKit is not available on this device."
            return
        }

        isLoading = true

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            isAuthorized = true
            await fetchAllTodayData()
        } catch {
            errorMessage = "HealthKit authorization failed: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Fetch All Today Data

    func fetchAllTodayData() async {
        async let steps = fetchTodaySteps()
        async let distance = fetchTodayDistance()
        async let activeCalories = fetchTodayActiveCalories()
        async let restingCalories = fetchTodayRestingCalories()
        async let exerciseMinutes = fetchTodayExerciseMinutes()
        async let standHours = fetchTodayStandHours()
        async let heartRate = fetchCurrentHeartRate()
        async let resting = fetchRestingHeartRate()
        async let weight = fetchLatestWeight()
        async let bodyFat = fetchLatestBodyFat()

        todaySteps = await steps
        todayDistance = await distance
        todayActiveCalories = await activeCalories
        todayRestingCalories = await restingCalories
        todayExerciseMinutes = await exerciseMinutes
        todayStandHours = await standHours
        currentHeartRate = await heartRate
        restingHeartRate = await resting
        latestWeight = await weight
        latestBodyFat = await bodyFat

        await fetchWeeklyData()
    }

    func refreshData() async {
        await fetchAllTodayData()
    }

    // MARK: - Steps

    func fetchTodaySteps() async -> Int {
        let quantity = await fetchTodayQuantity(
            type: HKQuantityType(.stepCount),
            unit: .count(),
            options: .cumulativeSum
        )
        return Int(quantity)
    }

    func fetchSteps(for date: Date) async -> Int {
        let quantity = await fetchDayQuantity(
            for: date,
            type: HKQuantityType(.stepCount),
            unit: .count(),
            options: .cumulativeSum
        )
        return Int(quantity)
    }

    // MARK: - Distance

    func fetchTodayDistance() async -> Double {
        await fetchTodayQuantity(
            type: HKQuantityType(.distanceWalkingRunning),
            unit: .meter(),
            options: .cumulativeSum
        )
    }

    // MARK: - Calories

    func fetchTodayActiveCalories() async -> Double {
        await fetchTodayQuantity(
            type: HKQuantityType(.activeEnergyBurned),
            unit: .kilocalorie(),
            options: .cumulativeSum
        )
    }

    func fetchTodayRestingCalories() async -> Double {
        await fetchTodayQuantity(
            type: HKQuantityType(.basalEnergyBurned),
            unit: .kilocalorie(),
            options: .cumulativeSum
        )
    }

    func fetchActiveCalories(for date: Date) async -> Double {
        await fetchDayQuantity(
            for: date,
            type: HKQuantityType(.activeEnergyBurned),
            unit: .kilocalorie(),
            options: .cumulativeSum
        )
    }

    // MARK: - Exercise

    func fetchTodayExerciseMinutes() async -> Double {
        await fetchTodayQuantity(
            type: HKQuantityType(.appleExerciseTime),
            unit: .minute(),
            options: .cumulativeSum
        )
    }

    func fetchExerciseMinutes(for date: Date) async -> Double {
        await fetchDayQuantity(
            for: date,
            type: HKQuantityType(.appleExerciseTime),
            unit: .minute(),
            options: .cumulativeSum
        )
    }

    // MARK: - Stand

    func fetchTodayStandHours() async -> Double {
        await fetchTodayQuantity(
            type: HKQuantityType(.appleStandTime),
            unit: .hour(),
            options: .cumulativeSum
        )
    }

    // MARK: - Heart Rate

    func fetchCurrentHeartRate() async -> Double? {
        await fetchLatestQuantity(
            type: HKQuantityType(.heartRate),
            unit: HKUnit.count().unitDivided(by: .minute())
        )
    }

    func fetchRestingHeartRate() async -> Double? {
        await fetchLatestQuantity(
            type: HKQuantityType(.restingHeartRate),
            unit: HKUnit.count().unitDivided(by: .minute())
        )
    }

    func fetchHeartRateSamples(from startDate: Date, to endDate: Date) async -> [(Date, Double)] {
        let type = HKQuantityType(.heartRate)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let unit = HKUnit.count().unitDivided(by: .minute())

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, _ in
                let result: [(Date, Double)] = (samples as? [HKQuantitySample] ?? []).map {
                    ($0.startDate, $0.quantity.doubleValue(for: unit))
                }
                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Body Metrics

    func fetchLatestWeight() async -> Double? {
        await fetchLatestQuantity(
            type: HKQuantityType(.bodyMass),
            unit: .gramUnit(with: .kilo)
        )
    }

    func fetchLatestBodyFat() async -> Double? {
        if let value = await fetchLatestQuantity(
            type: HKQuantityType(.bodyFatPercentage),
            unit: .percent()
        ) {
            return value * 100
        }
        return nil
    }

    func saveWeight(_ kg: Double, date: Date = Date()) async throws {
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    func saveBodyFat(_ percent: Double, date: Date = Date()) async throws {
        let type = HKQuantityType(.bodyFatPercentage)
        let quantity = HKQuantity(unit: .percent(), doubleValue: percent / 100)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    // MARK: - Sleep

    func fetchSleepSessions(from startDate: Date, to endDate: Date) async -> [HKCategorySample] {
        let type = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            healthStore.execute(query)
        }
    }

    func fetchLastNightSleep() async -> Double {
        let end = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .hour, value: -10, to: end)!
        let samples = await fetchSleepSessions(from: start, to: Date())

        var totalMinutes: Double = 0
        for sample in samples {
            if sample.value != HKCategoryValueSleepAnalysis.awake.rawValue {
                totalMinutes += sample.endDate.timeIntervalSince(sample.startDate) / 60
            }
        }
        return totalMinutes
    }

    // MARK: - Workouts

    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [HKWorkout] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: HKObjectType.workoutType(),
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                continuation.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            healthStore.execute(query)
        }
    }

    func saveWorkout(
        type: HKWorkoutActivityType,
        start: Date,
        end: Date,
        calories: Double,
        distance: Double?
    ) async throws {
        var metadata: [String: Any] = [:]
        var totalEnergyBurned: HKQuantity? = nil
        var totalDistance: HKQuantity? = nil

        if calories > 0 {
            totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        }

        if let dist = distance, dist > 0 {
            totalDistance = HKQuantity(unit: .meter(), doubleValue: dist)
        }

        let workout = HKWorkout(
            activityType: type,
            start: start,
            end: end,
            duration: end.timeIntervalSince(start),
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: totalDistance,
            metadata: metadata
        )

        try await healthStore.save(workout)
    }

    // MARK: - Weekly Data

    func fetchWeeklyData() async {
        let calendar = Calendar.current
        var steps: [Int] = []
        var calories: [Double] = []
        var exercise: [Double] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else {
                steps.append(0)
                calories.append(0)
                exercise.append(0)
                continue
            }

            async let s = fetchSteps(for: date)
            async let c = fetchActiveCalories(for: date)
            async let e = fetchExerciseMinutes(for: date)

            steps.append(await s)
            calories.append(await c)
            exercise.append(await e)
        }

        weeklySteps = steps
        weeklyCalories = calories
        weeklyExercise = exercise
    }

    // MARK: - Health Summary

    func fetchHealthSummary(for date: Date) async -> HealthSummary {
        async let steps = fetchSteps(for: date)
        async let distance = fetchDayQuantity(
            for: date,
            type: HKQuantityType(.distanceWalkingRunning),
            unit: .meter(),
            options: .cumulativeSum
        )
        async let activeCalories = fetchActiveCalories(for: date)
        async let restingCalories = fetchDayQuantity(
            for: date,
            type: HKQuantityType(.basalEnergyBurned),
            unit: .kilocalorie(),
            options: .cumulativeSum
        )
        async let exerciseMinutes = fetchExerciseMinutes(for: date)
        async let standHours = fetchDayQuantity(
            for: date,
            type: HKQuantityType(.appleStandTime),
            unit: .hour(),
            options: .cumulativeSum
        )
        async let heartRate = fetchCurrentHeartRate()
        async let resting = fetchRestingHeartRate()

        return HealthSummary(
            date: date,
            steps: await steps,
            distanceMeters: await distance,
            activeCalories: await activeCalories,
            restingCalories: await restingCalories,
            exerciseMinutes: await exerciseMinutes,
            standHours: await standHours,
            averageHeartRate: await heartRate,
            restingHeartRate: await resting,
            sleepHours: nil
        )
    }

    // MARK: - Generic Helpers

    private func fetchTodayQuantity(
        type: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions
    ) async -> Double {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Date()
        return await fetchQuantityBetween(start: start, end: end, type: type, unit: unit, options: options)
    }

    private func fetchDayQuantity(
        for date: Date,
        type: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions
    ) async -> Double {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return await fetchQuantityBetween(start: start, end: end, type: type, unit: unit, options: options)
    }

    private func fetchQuantityBetween(
        start: Date,
        end: Date,
        type: HKQuantityType,
        unit: HKUnit,
        options: HKStatisticsOptions
    ) async -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, _ in
                let value: Double
                if options.contains(.cumulativeSum) {
                    value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                } else {
                    value = statistics?.mostRecentQuantity()?.doubleValue(for: unit) ?? 0
                }
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func fetchLatestQuantity(type: HKQuantityType, unit: HKUnit) async -> Double? {
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: nil,
                limit: 1,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, _ in
                let value = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }
}
