//
//  ActivityRingsView.swift
//  FitPulse
//
//  Activity rings display (Move/Exercise/Stand)
//

import SwiftUI

struct ActivityRingsView: View {
    let rings: ActivityRings

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                // Rings
                ZStack {
                    // Stand Ring (outermost)
                    RingShape(progress: rings.standProgress, ringWidth: 18)
                        .frame(width: 160, height: 160)
                        .foregroundColor(.fitPulseBlue.opacity(0.2))

                    RingShape(progress: rings.standProgress, ringWidth: 18)
                        .trim(from: 0, to: rings.standProgress)
                        .frame(width: 160, height: 160)
                        .foregroundColor(.fitPulseBlue)
                        .rotationEffect(.degrees(-90))

                    // Exercise Ring (middle)
                    RingShape(progress: rings.exerciseProgress, ringWidth: 18)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.fitPulseGreen.opacity(0.2))

                    RingShape(progress: rings.exerciseProgress, ringWidth: 18)
                        .trim(from: 0, to: rings.exerciseProgress)
                        .frame(width: 120, height: 120)
                        .foregroundColor(.fitPulseGreen)
                        .rotationEffect(.degrees(-90))

                    // Move Ring (innermost)
                    RingShape(progress: rings.moveProgress, ringWidth: 18)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.fitPulseRed.opacity(0.2))

                    RingShape(progress: rings.moveProgress, ringWidth: 18)
                        .trim(from: 0, to: rings.moveProgress)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.fitPulseRed)
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 180, height: 180)

                Spacer()

                // Ring details
                VStack(alignment: .leading, spacing: 16) {
                    RingDetailRow(
                        color: .fitPulseRed,
                        icon: "flame.fill",
                        label: "Move",
                        value: "\(Int(rings.moveCalories)) cal",
                        progress: rings.moveProgress
                    )
                    RingDetailRow(
                        color: .fitPulseGreen,
                        icon: "bolt.fill",
                        label: "Exercise",
                        value: "\(Int(rings.exerciseMinutes)) min",
                        progress: rings.exerciseProgress
                    )
                    RingDetailRow(
                        color: .fitPulseBlue,
                        icon: "figure.stand",
                        label: "Stand",
                        value: "\(Int(rings.standHours)) hrs",
                        progress: rings.standProgress
                    )
                }
            }

            if rings.allRingsClosed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.fitPulseGreen)
                    Text("All rings closed! Great work today! 🎉")
                        .font(.subheadline.bold())
                        .foregroundColor(.fitPulseGreen)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}

struct RingShape: Shape {
    var progress: Double
    var ringWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - ringWidth / 2
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(0),
            endAngle: .degrees(360),
            clockwise: false
        )
        return path
    }
}

struct RingDetailRow: View {
    let color: Color
    let icon: String
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline.bold())
            }

            Spacer()

            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}

// MARK: - Small Rings Widget
struct SmallActivityRings: View {
    let rings: ActivityRings

    var body: some View {
        ZStack {
            // Stand
            Circle()
                .stroke(Color.fitPulseBlue.opacity(0.2), lineWidth: 8)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: rings.standProgress)
                .stroke(Color.fitPulseBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))

            // Exercise
            Circle()
                .stroke(Color.fitPulseGreen.opacity(0.2), lineWidth: 8)
                .frame(width: 60, height: 60)

            Circle()
                .trim(from: 0, to: rings.exerciseProgress)
                .stroke(Color.fitPulseGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))

            // Move
            Circle()
                .stroke(Color.fitPulseRed.opacity(0.2), lineWidth: 8)
                .frame(width: 40, height: 40)

            Circle()
                .trim(from: 0, to: rings.moveProgress)
                .stroke(Color.fitPulseRed, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(-90))
        }
    }
}
