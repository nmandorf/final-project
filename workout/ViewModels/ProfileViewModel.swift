//
//  ProfileViewModel.swift
//  workout
//
//  Created by Codex on 12/5/25.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var history: [SavedWorkout] = []
    
    private let defaults: UserDefaults
    private let workoutLoader: WorkoutLoader
    
    init(
        defaults: UserDefaults = .standard,
        workoutLoader: WorkoutLoader = .shared
    ) {
        self.defaults = defaults
        self.workoutLoader = workoutLoader
    }
    
    func refreshHistory() {
        let data = defaults.data(forKey: "workoutHistory")
        let decoder = JSONDecoder()
        let workouts = (try? decoder.decode([SavedWorkout].self, from: data ?? Data())) ?? []
        history = workouts
    }
    
    func exerciseName(for id: String) -> String {
        workoutLoader.loadWorkoutSchedule()?
            .schedule
            .flatMap { $0.exercises }
            .first(where: { $0.id == id })?
            .name ?? "Exercise"
    }
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
