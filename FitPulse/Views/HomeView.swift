//
//  HomeView.swift
//  FitPulse
//
//  Main dashboard / home screen
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(StoreKitManager.self) private var storeKitManager
    @Query private var goals: [UserGoal]

    @State private var viewModel: DashboardViewModel?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    homeContent(vm: vm)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("FitPulse")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showPaywall = true
                    } label: {
                        if storeKitManager.isPremium {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.fitPulseOrange)
                        } else {
                            Text("Premium")
                                .font(.caption.bold())
                                .foregroundColor(.fitPulseGreen)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            let vm = DashboardViewModel(healthKitService: healthKitService)
            viewModel = vm

            if !healthKitService.isAuthorized {
                await healthKitService.requestAuthorization()
            }

            await vm.loadData(goals: goals.first)
        }
    }

    @ViewBuilder
    private func homeContent(vm: DashboardViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {

                // Greeting
                greetingSection(vm: vm)

                // Activity Rings
                ActivityRingsView(rings: vm.activityRings)
                    .padding(.horizontal)

                // Stat Cards
                statCardsSection(vm: vm)

                // Heart Rate
                if let hr = vm.currentHeartRate {
                    heartRateSection(hr: hr, resting: vm.restingHeartRate)
                }

                // Weekly Steps Chart
                weeklyStepsSection(vm: vm)

                // Quick Actions
                quickActionsSection()
            }
            .padding(.bottom, 32)
        }
        .refreshable {
            await vm.refresh()
        }
    }

    private func greetingSection(vm: DashboardViewModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.greeting)
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Let's crush today's goals!")
                    .font(.title.bold())
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.fitPulseGreen.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "heart.fill")
                    .font(.title2)
                    .foregroundColor(.fitPulseGreen)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private func statCardsSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(vm.statCards) { card in
                    StatCardView(card: card)
                }
            }
            .padding(.horizontal)
        }
    }

    private func heartRateSection(hr: Double, resting: Double?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 16) {
                HeartRateCard(
                    title: "Current",
                    value: "\(Int(hr))",
                    unit: "BPM",
                    icon: "heart.fill",
                    color: .fitPulseRed
                )
                if let resting = resting {
                    HeartRateCard(
                        title: "Resting",
                        value: "\(Int(resting))",
                        unit: "BPM",
                        icon: "heart",
                        color: .fitPulsePurple
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    private func weeklyStepsSection(vm: DashboardViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weekly Steps")
                    .font(.headline)
                Spacer()
                Text("Avg: \(averageSteps(vm.weeklySteps).formatted())")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            WeeklyBarChart(
                values: vm.weeklySteps.map { Double($0) },
                goal: Double(vm.stepGoal),
                color: .fitPulseGreen,
                labels: dayLabels()
            )
            .frame(height: 120)
            .padding(.horizontal)
        }
    }

    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(quickWorkoutTypes, id: \.self) { type in
                        QuickWorkoutButton(type: type)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func averageSteps(_ steps: [Int]) -> Int {
        guard !steps.isEmpty else { return 0 }
        let nonZero = steps.filter { $0 > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0, +) / nonZero.count
    }

    private func dayLabels() -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return (0..<7).map { offset in
            let date = Calendar.current.date(byAdding: .day, value: -(6 - offset), to: Date())!
            return formatter.string(from: date)
        }
    }

    private var quickWorkoutTypes: [WorkoutType] {
        [.running, .walking, .cycling, .strengthTraining, .yoga, .swimming]
    }
}

// MARK: - Subviews

struct StatCardView: View {
    let card: StatCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: card.icon)
                    .font(.subheadline)
                    .foregroundColor(card.color)
                Spacer()
                Text("\(Int(card.progress * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(card.value)
                .font(.title2.bold())

            Text(card.subtitle)
                .font(.caption)
                .foregroundColor(.secondary)

            ProgressView(value: card.progress)
                .tint(card.color)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct HeartRateCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .foregroundColor(color)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.title.bold())
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct WeeklyBarChart: View {
    let values: [Double]
    let goal: Double
    let color: Color
    let labels: [String]

    var maxValue: Double {
        max(values.max() ?? 0, goal)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(value >= goal ? color : color.opacity(0.4))
                        .frame(height: maxValue > 0 ? CGFloat(value / maxValue) * 80 : 4)

                    Text(labels[safe: index] ?? "")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickWorkoutButton: View {
    let type: WorkoutType

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(colorForType(type).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: type.icon)
                    .font(.title3)
                    .foregroundColor(colorForType(type))
            }
            Text(type.rawValue.components(separatedBy: " ").first ?? type.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func colorForType(_ type: WorkoutType) -> Color {
        switch type {
        case .running: return .fitPulseGreen
        case .walking: return .fitPulsePurple
        case .cycling: return .fitPulseBlue
        case .strengthTraining: return .fitPulseOrange
        case .yoga: return .fitPulsePurple
        case .swimming: return .fitPulseBlue
        default: return .fitPulseGreen
        }
    }
}

// MARK: - Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
