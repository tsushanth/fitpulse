//
//  WorkoutsView.swift
//  FitPulse
//
//  Workout history and logging view
//

import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(HealthKitService.self) private var healthKitService
    @Environment(StoreKitManager.self) private var storeKitManager
    @Query(sort: \Workout.startDate, order: .reverse) private var workouts: [Workout]

    @State private var viewModel: WorkoutViewModel?
    @State private var showAddWorkout = false
    @State private var showPaywall = false
    @State private var selectedFilter: WorkoutType? = nil

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    workoutsContent(vm: vm)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddWorkout = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.fitPulseGreen)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddWorkout) {
            if let vm = viewModel {
                AddWorkoutView(viewModel: vm)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .task {
            let vm = WorkoutViewModel(healthKitService: healthKitService)
            viewModel = vm
            vm.updateStats(from: workouts)
        }
        .onChange(of: workouts) { _, newWorkouts in
            viewModel?.updateStats(from: newWorkouts)
        }
    }

    @ViewBuilder
    private func workoutsContent(vm: WorkoutViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {

                // Stats Summary
                workoutStatsSection(vm: vm)

                // Filter
                filterSection(vm: vm)

                // Workout List
                let filtered = vm.filteredWorkouts(workouts)
                if filtered.isEmpty {
                    emptyState
                } else {
                    workoutsList(filtered, vm: vm)
                }
            }
            .padding(.bottom, 32)
        }
        .searchable(text: Binding(
            get: { vm.searchText },
            set: { vm.searchText = $0 }
        ), prompt: "Search workouts")
    }

    private func workoutStatsSection(vm: WorkoutViewModel) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatsSmallCard(
                    value: "\(vm.stats.totalWorkouts)",
                    label: "Total",
                    icon: "figure.run",
                    color: .fitPulseGreen
                )
                StatsSmallCard(
                    value: "\(vm.stats.thisWeekWorkouts)",
                    label: "This Week",
                    icon: "calendar.badge.clock",
                    color: .fitPulseBlue
                )
                StatsSmallCard(
                    value: "\(Int(vm.stats.totalCalories)) cal",
                    label: "Total Cal",
                    icon: "flame.fill",
                    color: .fitPulseRed
                )
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }

    private func filterSection(vm: WorkoutViewModel) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                    vm.selectedFilter = nil
                }
                ForEach(WorkoutType.allCases, id: \.self) { type in
                    FilterChip(
                        label: type.rawValue,
                        isSelected: selectedFilter == type
                    ) {
                        selectedFilter = type
                        vm.selectedFilter = type
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func workoutsList(_ workouts: [Workout], vm: WorkoutViewModel) -> some View {
        LazyVStack(spacing: 12) {
            ForEach(workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutRowView(workout: workout)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.run.circle")
                .font(.system(size: 60))
                .foregroundColor(.fitPulseGreen.opacity(0.5))

            Text("No Workouts Yet")
                .font(.title2.bold())

            Text("Tap + to log your first workout")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Log a Workout") {
                showAddWorkout = true
            }
            .buttonStyle(.borderedProminent)
            .tint(.fitPulseGreen)
        }
        .padding(.top, 60)
    }
}

// MARK: - Subviews

struct WorkoutRowView: View {
    let workout: Workout

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorForWorkout(workout.workoutTypeEnum).opacity(0.15))
                    .frame(width: 52, height: 52)
                Image(systemName: workout.workoutTypeEnum.icon)
                    .font(.title3)
                    .foregroundColor(colorForWorkout(workout.workoutTypeEnum))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.workoutType)
                    .font(.subheadline.bold())
                Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(workout.durationFormatted)
                    .font(.subheadline.bold())
                Text("\(Int(workout.caloriesBurned)) cal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }

    private func colorForWorkout(_ type: WorkoutType) -> Color {
        switch type {
        case .running: return .fitPulseGreen
        case .cycling: return .fitPulseBlue
        case .swimming: return .cyan
        case .strengthTraining: return .fitPulseOrange
        case .yoga: return .fitPulsePurple
        default: return .fitPulseGreen
        }
    }
}

struct WorkoutDetailView: View {
    let workout: Workout
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Header
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [.fitPulseGreen, .fitPulseBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 160)

                    VStack(spacing: 8) {
                        Image(systemName: workout.workoutTypeEnum.icon)
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                        Text(workout.workoutType)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DetailStatCard(label: "Duration", value: workout.durationFormatted, icon: "clock.fill", color: .fitPulseBlue)
                    DetailStatCard(label: "Calories", value: "\(Int(workout.caloriesBurned))", icon: "flame.fill", color: .fitPulseRed)
                    if let dist = workout.distanceFormatted {
                        DetailStatCard(label: "Distance", value: dist, icon: "map.fill", color: .fitPulseGreen)
                    }
                    if let hr = workout.averageHeartRate {
                        DetailStatCard(label: "Avg HR", value: "\(Int(hr)) BPM", icon: "heart.fill", color: .fitPulseRed)
                    }
                    if let steps = workout.steps {
                        DetailStatCard(label: "Steps", value: steps.formatted(), icon: "figure.walk", color: .fitPulseGreen)
                    }
                }
                .padding(.horizontal)

                // Date
                VStack(alignment: .leading, spacing: 4) {
                    Label("Date & Time", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(workout.startDate.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)

                // Notes
                if let notes = workout.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Notes", systemImage: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 32)
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    modelContext.delete(workout)
                    dismiss()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct DetailStatCard: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(value)
                .font(.title3.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
    }
}

struct StatsSmallCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
            Text(value)
                .font(.subheadline.bold())
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.fitPulseGreen : Color.cardBackground)
                .cornerRadius(20)
        }
    }
}
