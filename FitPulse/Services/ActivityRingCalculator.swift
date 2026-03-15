//
//  ActivityRingCalculator.swift
//  FitPulse
//
//  Calculates and manages activity ring progress
//

import Foundation
import SwiftUI

final class ActivityRingCalculator {
    static let shared = ActivityRingCalculator()
    private init() {}

    func calculateRings(
        activeCalories: Double,
        moveGoal: Double,
        exerciseMinutes: Double,
        exerciseGoal: Double,
        standHours: Double,
        standGoal: Double
    ) -> ActivityRings {
        ActivityRings(
            moveCalories: activeCalories,
            moveGoal: moveGoal,
            exerciseMinutes: exerciseMinutes,
            exerciseGoal: exerciseGoal,
            standHours: standHours,
            standGoal: standGoal
        )
    }

    func weeklyAverage(for values: [Double], goal: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let avg = values.reduce(0, +) / Double(values.count)
        return min(avg / goal, 1.0)
    }

    func trend(for values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let recent = values.suffix(3).reduce(0, +) / 3
        let earlier = values.prefix(3).reduce(0, +) / 3
        guard earlier > 0 else { return 0 }
        return (recent - earlier) / earlier
    }

    func streakDays(moveGoal: Double, weeklyCalories: [Double]) -> Int {
        var streak = 0
        for calories in weeklyCalories.reversed() {
            if calories >= moveGoal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    func ringColor(for ringType: RingType) -> Color {
        switch ringType {
        case .move: return .fitPulseRed
        case .exercise: return .fitPulseGreen
        case .stand: return .fitPulseBlue
        }
    }

    enum RingType {
        case move, exercise, stand
    }
}

// MARK: - Activity Ring View Helper
struct ActivityRingData {
    let progress: Double
    let color: Color
    let icon: String
    let label: String
    let value: String
    let goal: String
}

extension ActivityRings {
    var moveRingData: ActivityRingData {
        ActivityRingData(
            progress: moveProgress,
            color: .fitPulseRed,
            icon: "flame.fill",
            label: "Move",
            value: "\(Int(moveCalories)) cal",
            goal: "\(Int(moveGoal)) goal"
        )
    }

    var exerciseRingData: ActivityRingData {
        ActivityRingData(
            progress: exerciseProgress,
            color: .fitPulseGreen,
            icon: "bolt.fill",
            label: "Exercise",
            value: "\(Int(exerciseMinutes)) min",
            goal: "\(Int(exerciseGoal)) goal"
        )
    }

    var standRingData: ActivityRingData {
        ActivityRingData(
            progress: standProgress,
            color: .fitPulseBlue,
            icon: "figure.stand",
            label: "Stand",
            value: "\(Int(standHours)) hrs",
            goal: "\(Int(standGoal)) goal"
        )
    }

    var ringDataList: [ActivityRingData] {
        [moveRingData, exerciseRingData, standRingData]
    }
}
