//
//  HomeViewModel.swift
//  workout
//
//  Created by Codex on 12/5/25.
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var trackingStats = TrackingStats()
    
    private let defaults: UserDefaults
    private let workoutLoader: WorkoutLoader
    
    init(
        defaults: UserDefaults = .standard,
        workoutLoader: WorkoutLoader = .shared
    ) {
        self.defaults = defaults
        self.workoutLoader = workoutLoader
    }
    
    func loadTrackingStats() {
        guard let trackedID = defaults.string(forKey: "trackedExerciseID") else {
            trackingStats = TrackingStats()
            return
        }
        
        let history: [SavedWorkout]
        if let data = defaults.data(forKey: "workoutHistory"),
           let decoded = try? JSONDecoder().decode([SavedWorkout].self, from: data) {
            history = decoded
        } else {
            history = []
        }
        
        let exerciseName = workoutLoader.loadWorkoutSchedule()?
            .schedule
            .flatMap { $0.exercises }
            .first(where: { $0.id == trackedID })?
            .name ?? "Tracked Exercise"
        
        let orderedHistory = history.sorted { $0.timestamp < $1.timestamp }
        let entries = orderedHistory.compactMap { entry -> (weight: Double, date: Date)? in
            guard let weight = entry.exerciseWeights[trackedID], weight.isFinite else {
                return nil
            }
            return (weight, entry.timestamp)
        }
        
        let weights = entries.map { $0.weight }
        let dates = entries.map { $0.date }
        
        let repsValues = orderedHistory
            .flatMap { $0.repsByExercise[trackedID] ?? [] }
            .compactMap { value -> Double? in
                guard let parsed = Double(value), parsed.isFinite else {
                    return nil
                }
                return parsed
            }
        
        let averageReps = repsValues.isEmpty ? nil : repsValues.reduce(0, +) / Double(repsValues.count)
        
        trackingStats = TrackingStats(
            exerciseName: exerciseName,
            weights: weights,
            dates: dates,
            averageReps: averageReps
        )
    }
}

struct TrackingStats {
    var exerciseName: String = "No exercise tracked"
    var weights: [Double] = []
    var dates: [Date] = []
    var averageReps: Double?
    
    var subtitle: String {
        exerciseName
    }
}
