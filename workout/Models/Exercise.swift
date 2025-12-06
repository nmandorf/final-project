//
//  Exercise.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import Foundation

struct Exercise: Identifiable, Codable {
    let id: String
    let name: String
    let sets: Int?
    let reps: String?
    let weight: Double?
    
    enum CodingKeys: String, CodingKey {
        case name, sets, reps, weight
    }
    
    init(id: String = UUID().uuidString, name: String, sets: Int?, reps: String?, weight: Double?) {
        self.id = id
        self.name = name
        self.sets = sets
        self.reps = reps
        self.weight = weight
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID().uuidString
        self.name = try container.decode(String.self, forKey: .name)
        self.sets = try container.decodeIfPresent(Int.self, forKey: .sets)
        self.reps = try container.decodeIfPresent(String.self, forKey: .reps)
        self.weight = Exercise.decodeWeight(from: container)
    }
    
    private static func decodeWeight(from container: KeyedDecodingContainer<CodingKeys>) -> Double? {
        if let numericWeight = try? container.decode(Double.self, forKey: .weight) {
            return numericWeight
        }
        
        if let stringWeight = try? container.decode(String.self, forKey: .weight),
           let parsedWeight = Double(stringWeight) {
            return parsedWeight
        }
        
        return nil
    }
}

struct WorkoutDay: Identifiable, Codable {
    let id: String
    let day: String
    let exercises: [Exercise]
    
    enum CodingKeys: String, CodingKey {
        case day, exercises
    }
    
    init(id: String = UUID().uuidString, day: String, exercises: [Exercise]) {
        self.id = id
        self.day = day
        self.exercises = exercises
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID().uuidString
        self.day = try container.decode(String.self, forKey: .day)
        self.exercises = try container.decode([Exercise].self, forKey: .exercises)
    }
}

struct WorkoutSchedule: Codable {
    let schedule: [WorkoutDay]
}
