//
//  SleepView.swift
//  FitPulse
//
//  Sleep tracking view
//

import SwiftUI
import SwiftData
import Charts

struct SleepView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(StoreKitManager.self) private var storeKitManager
    @Query(sort: \SleepSession.startDate, order: .reverse) private var sessions: [SleepSession]

    @State private var showAddSleep = false
    @State private var showPaywall = false
    @State private var lastNightSleep: Double = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {

                    // Last Night Summary
                    lastNightCard

                    // Sleep Goal
                    sleepGoalCard

                    // Weekly Overview
                    if storeKitManager.isPremium {
                        weeklyOverviewCard
                    } else {
                        premiumTeaser
                    }

                    // History
                    sleepHistory
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Sleep")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSleep = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.fitPulsePurple)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddSleep) {
            AddSleepView()
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            lastNightSleep = await healthKitService.fetchLastNightSleep()
        }
    }

    private var lastNightCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Night")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    let latest = sessions.first
                    let hours = latest?.totalMinutes ?? lastNightSleep
                    let h = Int(hours / 60)
                    let m = Int(hours) % 60

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(h)")
                            .font(.system(size: 52, weight: .bold))
                        Text("h")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("\(m)")
                            .font(.system(size: 52, weight: .bold))
                        Text("m")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }

                    if let session = latest {
                        Text(session.qualityLabel)
                            .font(.subheadline)
                            .foregroundColor(qualityColor(session.qualityLabel))
                    }
                }

                Spacer()

                SleepQualityGauge(hours: sessions.first.map { $0.totalMinutes / 60 } ?? lastNightSleep / 60)
            }

            if let session = sessions.first {
                sleepStagesBreakdown(session: session)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.2, green: 0.1, blue: 0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .padding(.horizontal)
        .padding(.top)
    }

    private func sleepStagesBreakdown(session: SleepSession) -> some View {
        VStack(spacing: 8) {
            Divider()
                .background(.white.opacity(0.2))

            HStack {
                SleepStageBar(
                    label: "Deep",
                    minutes: session.deepSleepMinutes,
                    total: session.totalMinutes,
                    color: Color(red: 0.3, green: 0.3, blue: 0.9)
                )
                SleepStageBar(
                    label: "REM",
                    minutes: session.remSleepMinutes,
                    total: session.totalMinutes,
                    color: .fitPulsePurple
                )
                SleepStageBar(
                    label: "Core",
                    minutes: session.coreSleepMinutes,
                    total: session.totalMinutes,
                    color: .fitPulseBlue
                )
                SleepStageBar(
                    label: "Awake",
                    minutes: session.awakeMinutes,
                    total: session.totalMinutes,
                    color: .gray
                )
            }
        }
    }

    private var sleepGoalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sleep Goal", systemImage: "target")
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("7-9 hours recommended")
                        .font(.subheadline)
                    Text("You got \(sleepHoursFormatted) last night")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                CircularProgressView(
                    progress: sleepProgress,
                    color: .fitPulsePurple,
                    size: 60
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private var weeklyOverviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)
                .padding(.horizontal)

            let weekSessions = weeklySessions
            Chart {
                ForEach(weekSessions, id: \.id) { session in
                    BarMark(
                        x: .value("Day", session.startDate, unit: .day),
                        y: .value("Hours", session.totalMinutes / 60)
                    )
                    .foregroundStyle(Color.fitPulsePurple)
                    .cornerRadius(4)
                }

                RuleMark(y: .value("Goal", 8))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.green)
            }
            .frame(height: 140)
            .padding(.horizontal)
        }
    }

    private var premiumTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Sleep Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Unlock detailed sleep trends with Premium")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "crown.fill")
                    .foregroundColor(.fitPulseOrange)
            }
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)
        }
    }

    private var sleepHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sleep History")
                .font(.headline)
                .padding(.horizontal)

            if sessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.fitPulsePurple.opacity(0.5))
                    Text("No sleep data yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Log your sleep to track patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(sessions) { session in
                        SleepSessionRow(session: session)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var sleepHoursFormatted: String {
        let hours = (sessions.first?.totalMinutes ?? lastNightSleep) / 60
        return String(format: "%.1f hrs", hours)
    }

    private var sleepProgress: Double {
        let hours = (sessions.first?.totalMinutes ?? lastNightSleep) / 60
        return min(hours / 8.0, 1.0)
    }

    private var weeklySessions: [SleepSession] {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return sessions.filter { $0.startDate >= weekAgo }
    }

    private func qualityColor(_ quality: String) -> Color {
        switch quality {
        case "Excellent": return .fitPulseGreen
        case "Good": return .blue
        case "Fair": return .fitPulseOrange
        default: return .fitPulseRed
        }
    }
}

// MARK: - Subviews

struct SleepStageBar: View {
    let label: String
    let minutes: Double
    let total: Double
    let color: Color

    var percentage: Int {
        guard total > 0 else { return 0 }
        return Int((minutes / total) * 100)
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(percentage)%")
                .font(.caption.bold())
                .foregroundColor(.white)
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct SleepQualityGauge: View {
    let hours: Double

    var quality: Double {
        if hours >= 9 { return 1.0 }
        if hours >= 7 { return 0.85 }
        if hours >= 6 { return 0.6 }
        if hours >= 5 { return 0.4 }
        return 0.2
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 8)
                .frame(width: 70, height: 70)

            Circle()
                .trim(from: 0, to: quality)
                .stroke(Color.fitPulsePurple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 70, height: 70)
                .rotationEffect(.degrees(-90))

            Image(systemName: "moon.fill")
                .font(.title2)
                .foregroundColor(.white)
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 6)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))

            Text("\(Int(progress * 100))%")
                .font(.caption2.bold())
                .foregroundColor(color)
        }
    }
}

struct SleepSessionRow: View {
    let session: SleepSession

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.fitPulsePurple.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "moon.fill")
                    .foregroundColor(.fitPulsePurple)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.bold())
                Text("\(session.startDate.formatted(date: .omitted, time: .shortened)) - \(session.endDate.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.durationFormatted)
                    .font(.subheadline.bold())
                Text(session.qualityLabel)
                    .font(.caption)
                    .foregroundColor(qualityColor(session.qualityLabel))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .cornerRadius(14)
    }

    private func qualityColor(_ quality: String) -> Color {
        switch quality {
        case "Excellent": return .fitPulseGreen
        case "Good": return .blue
        case "Fair": return .fitPulseOrange
        default: return .fitPulseRed
        }
    }
}

// MARK: - Add Sleep View
struct AddSleepView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var bedtime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var qualityScore: Double = 70
    @State private var notes: String = ""
    @State private var isSaving = false

    var duration: Double {
        let diff = wakeTime.timeIntervalSince(bedtime)
        if diff < 0 {
            return (diff + 86400) / 60
        }
        return diff / 60
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Sleep Times") {
                    DatePicker("Bedtime", selection: $bedtime, displayedComponents: .hourAndMinute)
                    DatePicker("Wake Time", selection: $wakeTime, displayedComponents: .hourAndMinute)
                }

                Section("Duration") {
                    let h = Int(duration) / 60
                    let m = Int(duration) % 60
                    Text("\(h) hours \(m) minutes")
                        .font(.title3.bold())
                        .foregroundColor(.fitPulsePurple)
                }

                Section("Sleep Quality") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quality: \(Int(qualityScore))%")
                        Slider(value: $qualityScore, in: 0...100, step: 1)
                            .tint(.fitPulsePurple)
                    }
                }

                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Log Sleep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveSleep()
                    }
                    .bold()
                    .disabled(isSaving)
                }
            }
        }
    }

    private func saveSleep() {
        isSaving = true
        let session = SleepSession(
            startDate: bedtime,
            endDate: wakeTime,
            totalMinutes: duration,
            deepSleepMinutes: duration * 0.2,
            remSleepMinutes: duration * 0.25,
            coreSleepMinutes: duration * 0.45,
            awakeMinutes: duration * 0.1,
            sleepQualityScore: Int(qualityScore),
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(session)
        AnalyticsService.shared.track(.sleepLogged)
        isSaving = false
        dismiss()
    }
}
