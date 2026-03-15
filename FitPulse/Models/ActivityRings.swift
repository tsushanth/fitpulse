//
//  ActivityRings.swift
//  FitPulse
//

import Foundation
import SwiftUI

struct ActivityRings: Equatable {
    var moveCalories: Double
    var moveGoal: Double
    var exerciseMinutes: Double
    var exerciseGoal: Double
    var standHours: Double
    var standGoal: Double

    init(
        moveCalories: Double = 0,
        moveGoal: Double = 500,
        exerciseMinutes: Double = 0,
        exerciseGoal: Double = 30,
        standHours: Double = 0,
        standGoal: Double = 12
    ) {
        self.moveCalories = moveCalories
        self.moveGoal = moveGoal
        self.exerciseMinutes = exerciseMinutes
        self.exerciseGoal = exerciseGoal
        self.standHours = standHours
        self.standGoal = standGoal
    }

    var moveProgress: Double {
        guard moveGoal > 0 else { return 0 }
        return min(moveCalories / moveGoal, 1.0)
    }

    var exerciseProgress: Double {
        guard exerciseGoal > 0 else { return 0 }
        return min(exerciseMinutes / exerciseGoal, 1.0)
    }

    var standProgress: Double {
        guard standGoal > 0 else { return 0 }
        return min(standHours / standGoal, 1.0)
    }

    var movePercentage: Int { Int(moveProgress * 100) }
    var exercisePercentage: Int { Int(exerciseProgress * 100) }
    var standPercentage: Int { Int(standProgress * 100) }

    var allRingsClosed: Bool {
        moveProgress >= 1.0 && exerciseProgress >= 1.0 && standProgress >= 1.0
    }

    static var empty: ActivityRings {
        ActivityRings()
    }
}

struct DailyActivity: Identifiable {
    let id = UUID()
    let date: Date
    let steps: Int
    let distance: Double
    let calories: Double
    let activeMinutes: Double
    let floors: Int

    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
