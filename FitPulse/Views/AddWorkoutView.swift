//
//  AddWorkoutView.swift
//  FitPulse
//
//  Log a new workout
//

import SwiftUI
import SwiftData

struct AddWorkoutView: View {
    let viewModel: WorkoutViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: WorkoutType = .running
    @State private var date = Date()
    @State private var durationMinutes: Double = 30
    @State private var distanceKm: String = ""
    @State private var calories: String = ""
    @State private var averageHR: String = ""
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var showTypePicker = false
    @State private var selectedCategory: WorkoutCategory? = nil

    var body: some View {
        NavigationStack {
            Form {
                // Workout Type
                Section("Workout Type") {
                    Button {
                        showTypePicker = true
                    } label: {
                        HStack {
                            Image(systemName: selectedType.icon)
                                .font(.title3)
                                .foregroundColor(.fitPulseGreen)
                                .frame(width: 32)
                            Text(selectedType.rawValue)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Date & Duration
                Section("When & How Long") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration: \(Int(durationMinutes)) min")
                            .font(.subheadline)
                        Slider(value: $durationMinutes, in: 1...240, step: 1)
                            .tint(.fitPulseGreen)
                    }
                }

                // Details
                Section("Details (Optional)") {
                    HStack {
                        Image(systemName: "map.fill")
                            .foregroundColor(.fitPulseBlue)
                            .frame(width: 24)
                        TextField("Distance (km)", text: $distanceKm)
                            .keyboardType(.decimalPad)
                    }

                    HStack {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.fitPulseRed)
                            .frame(width: 24)
                        TextField("Calories burned", text: $calories)
                            .keyboardType(.numberPad)
                    }

                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.fitPulseRed)
                            .frame(width: 24)
                        TextField("Avg heart rate (BPM)", text: $averageHR)
                            .keyboardType(.numberPad)
                    }
                }

                // Notes
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Estimated Calories
                if calories.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("Est. calories: ~\(estimatedCalories) kcal")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .bold()
                    .disabled(isSaving)
                }
            }
        }
        .sheet(isPresented: $showTypePicker) {
            WorkoutTypePickerView(selectedType: $selectedType)
        }
    }

    private var estimatedCalories: Int {
        Int(WorkoutService.shared.calculateCalories(
            workoutType: selectedType,
            durationSeconds: durationMinutes * 60
        ))
    }

    private func saveWorkout() {
        isSaving = true
        Task {
            await viewModel.addWorkout(
                type: selectedType,
                date: date,
                durationMinutes: durationMinutes,
                distanceKm: Double(distanceKm),
                calories: Double(calories),
                averageHR: Double(averageHR),
                notes: notes.isEmpty ? nil : notes,
                context: modelContext
            )
            isSaving = false
            dismiss()
        }
    }
}

struct WorkoutTypePickerView: View {
    @Binding var selectedType: WorkoutType
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: WorkoutCategory? = nil

    var filteredTypes: [WorkoutType] {
        guard let category = selectedCategory else { return WorkoutType.allCases }
        return WorkoutType.allCases.filter {
            WorkoutService.shared.category(for: $0) == category
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(label: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(WorkoutCategory.allCases, id: \.self) { cat in
                            FilterChip(label: cat.rawValue, isSelected: selectedCategory == cat) {
                                selectedCategory = cat
                            }
                        }
                    }
                    .padding()
                }

                Divider()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredTypes, id: \.self) { type in
                            Button {
                                selectedType = type
                                dismiss()
                            } label: {
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedType == type ? Color.fitPulseGreen : Color.cardBackground)
                                            .frame(width: 64, height: 64)
                                        Image(systemName: type.icon)
                                            .font(.title2)
                                            .foregroundColor(selectedType == type ? .white : .primary)
                                    }
                                    Text(type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Choose Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
