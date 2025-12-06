//
//  WorkoutLoader.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import Foundation

final class WorkoutLoader {
    static let shared = WorkoutLoader()
    
    private var cachedSchedule: WorkoutSchedule?
    
    private init() {}
    
    func loadWorkoutSchedule() -> WorkoutSchedule? {
        if let cachedSchedule {
            return cachedSchedule
        }
        
        guard let url = locateScheduleURL() else {
            print("Error: workoutSchedule.json not found in bundle or project directory")
            return nil
        }
        
        guard let data = try? Data(contentsOf: url) else {
            print("Error: Could not read data from \(url)")
            return nil
        }
        
        do {
            let schedule = try JSONDecoder().decode(WorkoutSchedule.self, from: data)
            cachedSchedule = schedule
            return schedule
        } catch {
            print("Error decoding workout schedule: \(error)")
            return nil
        }
    }
    
    func getTodayWorkout() -> WorkoutDay? {
        guard let schedule = loadWorkoutSchedule() else {
            return nil
        }
        
        let today = Date()
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: today)
        let dayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayName = dayNames[weekday - 1]
        
        return schedule.schedule.first { $0.day == todayName }
    }
    
    
    private func locateScheduleURL() -> URL? {
        
        let bundles = [Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        for bundle in bundles {
            if let url = bundle.url(forResource: "workoutSchedule", withExtension: "json") {
                return url
            }
            
            if let url = bundle.url(forResource: "workoutSchedule", withExtension: "json", subdirectory: "Models") {
                return url
            }
        }
        
       
        let fileManager = FileManager.default
        let searchPaths = [
            "Models/workoutSchedule.json",
            "workoutSchedule.json"
        ]
        
        let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        if let url = url(from: cwd, searchPaths: searchPaths, fileManager: fileManager) {
            return url
        }
        
      
        if let resourceURL = Bundle.main.resourceURL?.deletingLastPathComponent(),
           let url = url(from: resourceURL, searchPaths: searchPaths, fileManager: fileManager) {
            return url
        }
        
        return nil
    }
    
    private func url(from baseURL: URL, searchPaths: [String], fileManager: FileManager) -> URL? {
        for path in searchPaths {
            let candidate = baseURL.appendingPathComponent(path)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }
        return nil
    }
}
