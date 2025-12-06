//
//  MainTabView.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import SwiftUI

struct MainTabView: View {
    let user: User
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ExerciseView()
                .tabItem {
                    Label("Exercise", systemImage: "dumbbell.fill")
                }
                .tag(1)
            
            ProfileView(user: user)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(2)
        }
    }
}

#Preview {
    MainTabView(user: User(name: "John Doe"))
}


