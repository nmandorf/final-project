//
//  ExerciseViewModel.swift
//  workout
//
//  Created by Codex on 12/5/25.
//

import Foundation
import Combine

@MainActor
final class ExerciseViewModel: ObservableObject {
    @Published private(set) var todayWorkout: WorkoutDay?
    @Published var repsDoneByExercise: [String: [String]]
    @Published var saveMessage: String?
    @Published var trackedExerciseID: String?
    @Published var updatedWeights: [String: Double]
    
    private let workoutLoader: WorkoutLoader
    private let defaults: UserDefaults
    
    init(
        workoutLoader: WorkoutLoader = .shared,
        defaults: UserDefaults = .standard
    ) {
        self.workoutLoader = workoutLoader
        self.defaults = defaults
        let workout = workoutLoader.getTodayWorkout()
        self.todayWorkout = workout
        self.repsDoneByExercise = Self.initialReps(for: workout)
        self.updatedWeights = Self.initialWeights(for: workout)
        let storedTrackedID = defaults.string(forKey: "trackedExerciseID")
        let defaultID = workout?.exercises.first?.id ?? storedTrackedID
        self.trackedExerciseID = defaultID
        
        if let defaultID {
            defaults.set(defaultID, forKey: "trackedExerciseID")
        }
    }
    
    func displayWeight(for exercise: Exercise) -> Double? {
        if let updated = updatedWeights[exercise.id] {
            return updated
        }
        return exercise.weight
    }
    
    func reps(for exercise: Exercise) -> [String] {
        repsDoneByExercise[exercise.id] ?? Self.defaultReps(for: exercise)
    }
    
    func updateReps(_ values: [String], for exercise: Exercise) {
        repsDoneByExercise[exercise.id] = values
    }
    
    @discardableResult
    func saveWorkout() -> Bool {
        guard let workout = todayWorkout else { return false }
        
        let weights = Dictionary(uniqueKeysWithValues: workout.exercises.compactMap { exercise -> (String, Double)? in
            let baseWeight = updatedWeights[exercise.id] ?? exercise.weight
            guard let weight = baseWeight else { return nil }
            let finalWeight = adjustedWeight(for: exercise, baseWeight: weight)
            return (exercise.id, finalWeight)
        })
        updatedWeights.merge(weights) { _, new in new }
        
        let payload = SavedWorkout(
            day: workout.day,
            timestamp: Date(),
            repsByExercise: repsDoneByExercise,
            exerciseWeights: weights
        )
        
        do {
            let data = try JSONEncoder().encode(payload)
            defaults.set(data, forKey: "lastSavedWorkout")
            appendWorkoutHistory(payload)
            archiveWorkout(payload)
            resetReps()
            saveMessage = "Workout saved!"
            return true
        } catch {
            saveMessage = "Failed to save workout."
            return false
        }
    }
    
    func persistTrackedExercise(id: String?) {
        if let id {
            defaults.set(id, forKey: "trackedExerciseID")
        } else {
            defaults.removeObject(forKey: "trackedExerciseID")
        }
    }
    
    func firstFocusableFieldIdentifier() -> (exerciseID: String, index: Int)? {
        guard let workout = todayWorkout else {
            return nil
        }
        
        for exercise in workout.exercises {
            if let reps = repsDoneByExercise[exercise.id], !reps.isEmpty {
                return (exercise.id, 0)
            }
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    private static func initialReps(for workout: WorkoutDay?) -> [String: [String]] {
        guard let workout else { return [:] }
        var result: [String: [String]] = [:]
        for exercise in workout.exercises {
            result[exercise.id] = defaultReps(for: exercise)
        }
        return result
    }
    
    private static func initialWeights(for workout: WorkoutDay?) -> [String: Double] {
        guard let workout else { return [:] }
        return workout.exercises.reduce(into: [String: Double]()) { partial, exercise in
            if let weight = exercise.weight {
                partial[exercise.id] = weight
            }
        }
    }
    
    private static func defaultReps(for exercise: Exercise) -> [String] {
        let setCount = max(exercise.sets ?? 1, 1)
        return Array(repeating: "", count: setCount)
    }
    
    private func adjustedWeight(for exercise: Exercise, baseWeight: Double) -> Double {
        guard shouldIncreaseWeight(for: exercise) else {
            return baseWeight
        }
        return baseWeight + weightIncrement(for: baseWeight)
    }
    
    private func shouldIncreaseWeight(for exercise: Exercise) -> Bool {
        guard let suggestedMax = maxSuggestedReps(for: exercise),
              let recordedReps = repsDoneValues(for: exercise),
              !recordedReps.isEmpty else {
            return false
        }
        
        return (recordedReps.reduce(0, +) / recordedReps.count) >= suggestedMax
    }
    
    private func maxSuggestedReps(for exercise: Exercise) -> Int? {
        guard let repsString = exercise.reps else { return nil }
        let numbers = repsString
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }
        return numbers.max()
    }
    
    private func repsDoneValues(for exercise: Exercise) -> [Int]? {
        guard let repsStrings = repsDoneByExercise[exercise.id] else { return nil }
        let values = repsStrings.compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
        return values.isEmpty ? nil : values
    }
    
    private func weightIncrement(for weight: Double) -> Double {
        weight >= 50 ? 5 : 2.5
    }
    
    private func resetReps() {
        repsDoneByExercise = Self.initialReps(for: todayWorkout)
    }
    
    private func appendWorkoutHistory(_ newEntry: SavedWorkout) {
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()
        
        var history: [SavedWorkout] = []
        if let data = defaults.data(forKey: "workoutHistory"),
           let decoded = try? decoder.decode([SavedWorkout].self, from: data) {
            history = decoded
        }
        
        history.append(newEntry)
        if history.count > 20 {
            history.removeFirst(history.count - 20)
        }
        
        if let encoded = try? encoder.encode(history) {
            defaults.set(encoded, forKey: "workoutHistory")
        }
    }
    
    private func archiveWorkout(_ workout: SavedWorkout) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        var existing: [SavedWorkout] = []
        
        if let data = try? Data(contentsOf: archiveURL()),
           let decoded = try? JSONDecoder().decode([SavedWorkout].self, from: data) {
            existing = decoded
        }
        
        existing.append(workout)
        
        do {
            let data = try encoder.encode(existing)
            try data.write(to: archiveURL(), options: [.atomic])
        } catch {
            print("Failed to archive workout: \(error)")
        }
    }
    
    private func archiveURL() -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return directory.appendingPathComponent("savedWorkoutsArchive.json")
    }
}
