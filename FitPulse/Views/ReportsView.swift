//
//  ReportsView.swift
//  FitPulse
//
//  Weekly and monthly health reports
//

import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(StoreKitManager.self) private var storeKitManager
    @Query(sort: \Workout.startDate, order: .reverse) private var workouts: [Workout]

    @State private var viewModel: ReportsViewModel?
    @State private var showPaywall = false
    @State private var selectedPeriod: ReportPeriod = .week
    @State private var showShareSheet = false
    @State private var reportText = ""

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    reportsContent(vm: vm)
                } else {
                    ProgressView("Loading Reports...")
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if storeKitManager.isPremium {
                        Button {
                            if let vm = viewModel {
                                reportText = vm.generateReport(workouts: workouts)
                                showShareSheet = true
                            }
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.fitPulseOrange)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(text: reportText)
        }
        .task {
            let vm = ReportsViewModel(healthKitService: healthKitService)
            viewModel = vm
            await vm.loadReports(workouts: workouts)
        }
    }

    @ViewBuilder
    private func reportsContent(vm: ReportsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {

                // Period Selector
                periodSelector(vm: vm)

                // Summary Cards
                summaryCards(vm: vm)

                // Steps Chart
                stepsChartSection(vm: vm)

                // Calories Chart
                caloriesChartSection(vm: vm)

                // Exercise Chart
                exerciseChartSection(vm: vm)

                // Workout Breakdown (Premium)
                if storeKitManager.isPremium {
                    workoutBreakdownSection(vm: vm)
                } else {
                    premiumAnalyticsTeaser
                }
            }
            .padding(.bottom, 32)
        }
    }

    private func periodSelector(vm: ReportsViewModel) -> some View {
        Picker("Period", selection: $selectedPeriod) {
            ForEach(ReportPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
        .padding(.top)
        .onChange(of: selectedPeriod) { _, period in
            vm.selectedPeriod = period
        }
    }

    private func summaryCards(vm: ReportsViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(vm.weeklySummaryCards) { card in
                SummaryCardView(card: card)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func stepsChartSection(vm: ReportsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Steps", systemImage: "figure.walk")
                    .font(.headline)
                Spacer()
                Text("Goal: 10,000")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Chart {
                ForEach(Array(vm.weeklySteps.enumerated()), id: \.offset) { index, steps in
                    BarMark(
                        x: .value("Day", vm.dayLabels[safe: index] ?? ""),
                        y: .value("Steps", steps)
                    )
                    .foregroundStyle(steps >= 10000 ? Color.fitPulseGreen : Color.fitPulseGreen.opacity(0.4))
                    .cornerRadius(4)
                }

                RuleMark(y: .value("Goal", 10000))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.green.opacity(0.7))
            }
            .frame(height: 160)
            .padding(.horizontal)
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func caloriesChartSection(vm: ReportsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Active Calories", systemImage: "flame.fill")
                .font(.headline)
                .padding(.horizontal)

            Chart {
                ForEach(Array(vm.weeklyCalories.enumerated()), id: \.offset) { index, cal in
                    BarMark(
                        x: .value("Day", vm.dayLabels[safe: index] ?? ""),
                        y: .value("Calories", cal)
                    )
                    .foregroundStyle(Color.fitPulseRed.gradient)
                    .cornerRadius(4)
                }
            }
            .frame(height: 140)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func exerciseChartSection(vm: ReportsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Exercise Minutes", systemImage: "bolt.fill")
                    .font(.headline)
                Spacer()
                Text("Avg: \(Int(vm.weeklyExercise.filter { $0 > 0 }.reduce(0, +) / max(1, Double(vm.weeklyExercise.filter { $0 > 0 }.count)))) min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Chart {
                ForEach(Array(vm.weeklyExercise.enumerated()), id: \.offset) { index, mins in
                    LineMark(
                        x: .value("Day", vm.dayLabels[safe: index] ?? ""),
                        y: .value("Minutes", mins)
                    )
                    .foregroundStyle(Color.fitPulseOrange)
                    .symbol(Circle())
                    .symbolSize(40)

                    AreaMark(
                        x: .value("Day", vm.dayLabels[safe: index] ?? ""),
                        y: .value("Minutes", mins)
                    )
                    .foregroundStyle(Color.fitPulseOrange.opacity(0.1))
                }

                RuleMark(y: .value("Goal", 30))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundStyle(.orange.opacity(0.5))
            }
            .frame(height: 140)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private func workoutBreakdownSection(vm: ReportsViewModel) -> some View {
        let weekWorkouts = weeklyWorkouts

        return VStack(alignment: .leading, spacing: 12) {
            Text("Workout Breakdown")
                .font(.headline)
                .padding(.horizontal)

            if weekWorkouts.isEmpty {
                Text("No workouts this week")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                ForEach(weekWorkouts) { workout in
                    WorkoutRowView(workout: workout)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var premiumAnalyticsTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .font(.title2)
                    .foregroundColor(.fitPulseOrange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Analytics")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Workout trends, personal bests, and more with Premium")
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

    private var weeklyWorkouts: [Workout] {
        let weekStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return workouts.filter { $0.startDate >= weekStart }
    }
}

// MARK: - Subviews

struct SummaryCardView: View {
    let card: SummaryCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: card.icon)
                .font(.title3)
                .foregroundColor(card.color)

            Text(card.value)
                .font(.title3.bold())

            Text(card.title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(card.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [text], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
