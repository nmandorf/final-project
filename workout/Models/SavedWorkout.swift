//
//  SavedWorkout.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import Foundation

struct SavedWorkout: Codable {
    let day: String
    let timestamp: Date
    let repsByExercise: [String: [String]]
    let exerciseWeights: [String: Double]
    
    enum CodingKeys: String, CodingKey {
        case day
        case timestamp
        case repsByExercise
        case exerciseWeights
    }
    
    init(day: String, timestamp: Date, repsByExercise: [String: [String]], exerciseWeights: [String: Double]) {
        self.day = day
        self.timestamp = timestamp
        self.repsByExercise = repsByExercise
        self.exerciseWeights = exerciseWeights
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.day = try container.decode(String.self, forKey: .day)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.repsByExercise = try container.decode([String: [String]].self, forKey: .repsByExercise)
        self.exerciseWeights = try container.decodeIfPresent([String: Double].self, forKey: .exerciseWeights) ?? [:]
    }
}

