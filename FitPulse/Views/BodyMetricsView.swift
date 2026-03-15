//
//  BodyMetricsView.swift
//  FitPulse
//
//  Body metrics tracking: weight, BMI, body fat, etc.
//

import SwiftUI
import SwiftData
import Charts

struct BodyMetricsView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(StoreKitManager.self) private var storeKitManager
    @Query(sort: \BodyMetric.date, order: .reverse) private var metrics: [BodyMetric]

    @State private var viewModel: BodyMetricsViewModel?
    @State private var showAddMetric = false
    @State private var showPaywall = false
    @State private var selectedMetricType: BodyMetricType = .weight

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    bodyMetricsContent(vm: vm)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Body Metrics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMetric = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.fitPulseGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddMetric) {
            if let vm = viewModel {
                AddBodyMetricView(viewModel: vm)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            let vm = BodyMetricsViewModel(healthKitService: healthKitService)
            viewModel = vm
            await vm.loadHealthKitData()
        }
    }

    @ViewBuilder
    private func bodyMetricsContent(vm: BodyMetricsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 20) {

                // Overview Cards
                overviewSection(vm: vm)

                // BMI Card
                if let bmi = vm.latestBMI ?? computedBMI(vm: vm) {
                    bmiCard(bmi: bmi)
                }

                // Metric Type Selector
                metricTypePicker

                // Chart (Premium)
                if storeKitManager.isPremium {
                    metricsChart(vm: vm)
                } else {
                    premiumChartTeaser
                }

                // History
                metricsHistory(vm: vm)
            }
            .padding(.bottom, 32)
        }
    }

    private func overviewSection(vm: BodyMetricsViewModel) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricOverviewCard(
                type: .weight,
                metric: vm.latestMetric(for: .weight, from: metrics),
                trend: vm.trend(for: .weight, from: metrics)
            )
            MetricOverviewCard(
                type: .bodyFat,
                metric: vm.latestMetric(for: .bodyFat, from: metrics),
                trend: vm.trend(for: .bodyFat, from: metrics)
            )
            MetricOverviewCard(
                type: .muscleMass,
                metric: vm.latestMetric(for: .muscleMass, from: metrics),
                trend: vm.trend(for: .muscleMass, from: metrics)
            )
            MetricOverviewCard(
                type: .waterPercentage,
                metric: vm.latestMetric(for: .waterPercentage, from: metrics),
                trend: vm.trend(for: .waterPercentage, from: metrics)
            )
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private func bmiCard(bmi: Double) -> some View {
        let category = BMICategory(value: bmi)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("BMI", systemImage: "figure.stand")
                    .font(.headline)
                Spacer()
                Text(category.category)
                    .font(.subheadline.bold())
                    .foregroundColor(colorForBMICategory(category.color))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(colorForBMICategory(category.color).opacity(0.15))
                    .cornerRadius(8)
            }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1f", bmi))
                    .font(.system(size: 48, weight: .bold))
                Text("BMI")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // BMI Scale
            BMIScaleView(bmi: bmi)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    private var metricTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BodyMetricType.allCases, id: \.self) { type in
                    FilterChip(
                        label: type.rawValue,
                        isSelected: selectedMetricType == type
                    ) {
                        selectedMetricType = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func metricsChart(vm: BodyMetricsViewModel) -> some View {
        let chartData = vm.chartData(for: selectedMetricType, from: metrics)

        VStack(alignment: .leading, spacing: 8) {
            Text("\(selectedMetricType.rawValue) History")
                .font(.headline)
                .padding(.horizontal)

            if chartData.isEmpty {
                Text("No data yet. Log your first \(selectedMetricType.rawValue.lowercased())!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                Chart {
                    ForEach(chartData, id: \.0) { date, value in
                        LineMark(
                            x: .value("Date", date),
                            y: .value(selectedMetricType.rawValue, value)
                        )
                        .foregroundStyle(Color.fitPulseGreen)

                        AreaMark(
                            x: .value("Date", date),
                            y: .value(selectedMetricType.rawValue, value)
                        )
                        .foregroundStyle(Color.fitPulseGreen.opacity(0.1))

                        PointMark(
                            x: .value("Date", date),
                            y: .value(selectedMetricType.rawValue, value)
                        )
                        .foregroundStyle(Color.fitPulseGreen)
                    }
                }
                .frame(height: 180)
                .padding(.horizontal)
            }
        }
    }

    private var premiumChartTeaser: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 40))
                    .foregroundColor(.fitPulseGreen.opacity(0.5))
                Text("Detailed charts with Premium")
                    .font(.headline)
                Image(systemName: "crown.fill")
                    .foregroundColor(.fitPulseOrange)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(Color.cardBackground)
            .cornerRadius(20)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.fitPulseGreen.opacity(0.3), lineWidth: 1)
                    .padding(.horizontal)
            )
        }
    }

    private func metricsHistory(vm: BodyMetricsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Entries")
                .font(.headline)
                .padding(.horizontal)

            let typeMetrics = vm.metrics(for: selectedMetricType, from: metrics)
            if typeMetrics.isEmpty {
                Text("No \(selectedMetricType.rawValue.lowercased()) entries yet.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(typeMetrics.prefix(10)) { metric in
                        MetricHistoryRow(metric: metric)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func computedBMI(vm: BodyMetricsViewModel) -> Double? {
        guard let weight = vm.latestMetric(for: .weight, from: metrics)?.value,
              let height = vm.height, height > 0 else { return nil }
        return vm.calculateBMI(weight: weight, heightM: height)
    }

    private func colorForBMICategory(_ colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .fitPulseGreen
        case "orange": return .fitPulseOrange
        default: return .fitPulseRed
        }
    }
}

// MARK: - Subviews

struct MetricOverviewCard: View {
    let type: BodyMetricType
    let metric: BodyMetric?
    let trend: TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: type.icon)
                    .font(.subheadline)
                    .foregroundColor(.fitPulseGreen)
                Spacer()
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundColor(trend.color)
            }

            if let metric = metric {
                Text(metric.formattedValue)
                    .font(.title3.bold())
            } else {
                Text("--")
                    .font(.title3.bold())
                    .foregroundColor(.secondary)
            }

            Text(type.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct MetricHistoryRow: View {
    let metric: BodyMetric

    var body: some View {
        HStack {
            Text(metric.formattedValue)
                .font(.subheadline.bold())
            Spacer()
            Text(metric.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct BMIScaleView: View {
    let bmi: Double

    var position: CGFloat {
        let clamped = max(15.0, min(40.0, bmi))
        return CGFloat((clamped - 15.0) / 25.0)
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        colors: [.blue, .fitPulseGreen, .fitPulseOrange, .red],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .cornerRadius(4)
                    .frame(height: 8)

                    Circle()
                        .fill(.white)
                        .frame(width: 16, height: 16)
                        .shadow(radius: 2)
                        .offset(x: position * geo.size.width - 8, y: -4)
                }
            }
            .frame(height: 16)

            HStack {
                Text("15")
                Spacer()
                Text("18.5")
                Spacer()
                Text("25")
                Spacer()
                Text("30")
                Spacer()
                Text("40")
            }
            .font(.caption2)
            .foregroundColor(.secondary)
        }
    }
}

// MARK: - Add Body Metric View
struct AddBodyMetricView: View {
    let viewModel: BodyMetricsViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: BodyMetricType = .weight
    @State private var value: String = ""
    @State private var date = Date()
    @State private var notes: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Metric Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(BodyMetricType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Value") {
                    HStack {
                        TextField("Enter value", text: $value)
                            .keyboardType(.decimalPad)
                        Text(selectedType.unit)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Date") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Log Metric")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveMetric()
                    }
                    .bold()
                    .disabled(value.isEmpty || isSaving)
                }
            }
        }
    }

    private func saveMetric() {
        guard let doubleValue = Double(value) else { return }
        isSaving = true
        Task {
            await viewModel.addMetric(
                type: selectedType,
                value: doubleValue,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                context: modelContext
            )
            isSaving = false
            dismiss()
        }
    }
}
