//
//  ProfileView.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import SwiftUI

struct ProfileView: View {
    let user: User
    @State private var selection: ProfileTab = .details
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Profile Sections", selection: $selection) {
                    ForEach(ProfileTab.allCases, id: \.self) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                switch selection {
                case .details:
                    VStack(spacing: 12) {
                        Text("Profile")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(user.name)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .history:
                    WorkoutHistoryList(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
            .navigationTitle("Profile")
        }
        .onAppear {
            viewModel.refreshHistory()
        }
    }
}

private enum ProfileTab: CaseIterable {
    case details
    case history
    
    var title: String {
        switch self {
        case .details: return "Details"
        case .history: return "History"
        }
    }
}

struct WorkoutHistoryList: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Group {
            if viewModel.history.isEmpty {
                ContentUnavailableView("No Logged Workouts", systemImage: "tray")
            } else {
                List(viewModel.history.sorted { $0.timestamp > $1.timestamp }, id: \.timestamp) { workout in
                    Section("\(workout.day) • \(ProfileViewModel.dateFormatter.string(from: workout.timestamp))") {
                        ForEach(workout.repsByExercise.keys.sorted(), id: \.self) { exerciseID in
                            if let reps = workout.repsByExercise[exerciseID],
                               let weight = workout.exerciseWeights[exerciseID] {
                                NavigationLink {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Weight: \(Int(weight)) lbs")
                                            .font(.headline)
                                        Text("Reps: \(reps.joined(separator: ", "))")
                                        Spacer()
                                    }
                                    .padding()
                                    .navigationTitle("Workout Details")
                                } label: {
                                    VStack(alignment: .leading) {
                                        Text(viewModel.exerciseName(for: exerciseID))
                                            .font(.headline)
                                        Text("\(Int(weight)) lbs • \(reps.joined(separator: ", ")) reps")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .onAppear {
            viewModel.refreshHistory()
        }
    }
}

#Preview {
    ProfileView(user: User(name: "John Doe"))
}
