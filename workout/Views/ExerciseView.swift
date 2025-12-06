//
//  ExerciseView.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import SwiftUI

struct ExerciseView: View {
    @StateObject private var viewModel = ExerciseViewModel()
    @FocusState private var focusedField: ExerciseFocusField?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Text("Today's Workout")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.horizontal)
                .padding(.top)
            
            if let workout = viewModel.todayWorkout {
                if workout.exercises.isEmpty {
                    // Rest day
                    VStack {
                        Spacer()
                        Text("Rest Day")
                            .font(.title)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // Show exercises
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(workout.exercises) { exercise in
                                ExerciseCardView(
                                    exercise: exercise,
                                    displayWeight: viewModel.displayWeight(for: exercise),
                                    repsDone: Binding(
                                        get: { viewModel.reps(for: exercise) },
                                        set: { viewModel.updateReps($0, for: exercise) }
                                    ),
                                    trackedExerciseID: $viewModel.trackedExerciseID,
                                    focusedField: $focusedField
                                )
                            }
                        }
                        .padding()
                    }
                }
            } else {
                VStack {
                    Spacer()
                    Text("No workout scheduled for today.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            
            if viewModel.todayWorkout?.exercises.isEmpty == false {
                Button {
                    if viewModel.saveWorkout() {
                        focusFirstAvailableField()
                    }
                } label: {
                    Label("Save Workout", systemImage: "tray.and.arrow.down.fill")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding([.horizontal, .bottom])
                
                if let saveMessage = viewModel.saveMessage {
                    Text(saveMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onChange(of: viewModel.trackedExerciseID) { newValue in
            viewModel.persistTrackedExercise(id: newValue)
        }
        .onAppear {
            focusFirstAvailableField()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
    }
    
    private func focusFirstAvailableField() {
        guard let target = viewModel.firstFocusableFieldIdentifier() else {
            focusedField = nil
            return
        }
        
        DispatchQueue.main.async {
            focusedField = .set(exerciseID: target.exerciseID, index: target.index)
        }
    }
}

struct ExerciseCardView: View {
    let exercise: Exercise
    let displayWeight: Double?
    @Binding var repsDone: [String]
    @Binding var trackedExerciseID: String?
    var focusedField: FocusState<ExerciseFocusField?>.Binding
    
    private var isTracked: Bool {
        trackedExerciseID == exercise.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 10) {
                        if let sets = exercise.sets {
                            InfoChip(icon: "repeat", text: "\(sets) sets")
                        }
                        
                        if let reps = exercise.reps {
                            InfoChip(icon: "number", text: reps)
                        }
                        
                        if let weight = displayWeight {
                            InfoChip(icon: "scalemass", text: "\(Int(weight)) lbs")
                        }
                    }
                }
                
                Spacer()
                
                Button(action: toggleTracking) {
                    Image(systemName: isTracked ? "star.fill" : "star")
                        .foregroundColor(isTracked ? .yellow : .secondary)
                        .font(.title3)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5).opacity(isTracked ? 0.4 : 0.2))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isTracked ? "Stop tracking \(exercise.name)" : "Track \(exercise.name)")
            }
            
            Divider()
            
            if repsDone.isEmpty {
                Text("No sets to log for this exercise.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Log your reps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: repGridColumns(for: repsDone.count), spacing: 12) {
                        ForEach(repsDone.indices, id: \.self) { index in
                            VStack(spacing: 6) {
                                Text("Set \(index + 1)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                TextField("0", text: repsFieldBinding(for: index))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .focused(focusedField, equals: .set(exerciseID: exercise.id, index: index))
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(.systemBackground))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.secondary.opacity(0.3))
                                    )
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func repsFieldBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                repsDone.indices.contains(index) ? repsDone[index] : ""
            },
            set: { newValue in
                guard repsDone.indices.contains(index) else { return }
                var updatedReps = repsDone
                updatedReps[index] = newValue
                repsDone = updatedReps
            }
        )
    }
    
    private func toggleTracking() {
        if trackedExerciseID == exercise.id {
            trackedExerciseID = nil
        } else {
            trackedExerciseID = exercise.id
        }
    }
    
    private func repGridColumns(for totalSets: Int) -> [GridItem] {
        guard totalSets > 0 else {
            return [GridItem(.flexible())]
        }
        
        let columns = min(max(totalSets, 1), 4)
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }
}

private struct InfoChip: View {
    let icon: String
    let text: String
    
    var body: some View {
        Label {
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        } icon: {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color(.systemGray5))
        )
    }
}

enum ExerciseFocusField: Hashable {
    case set(exerciseID: String, index: Int)
}

#Preview {
    ExerciseView()
}
