//
//  ContentView.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import SwiftUI

struct ContentView: View {
    // Sample user data - in a real app, this would come from a ViewModel
    @State private var currentUser = User(name: "John Doe")
    
    var body: some View {
        VStack(spacing: 0) {
            // Header at the top
            HeaderView(user: currentUser)
            
            // Tab view as main content
            MainTabView(user: currentUser)
        }
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
