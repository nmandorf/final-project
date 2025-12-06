//
//  HeaderView.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import SwiftUI

struct HeaderView: View {
    let user: User
    
    var body: some View {
        HStack {
            // Profile picture and name on the left
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(user.name.prefix(1)).uppercased())
                            .font(.headline)
                            .foregroundColor(.blue)
                    )
                
                Text(user.name)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Today's date on the right
            Text(formattedDate)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
}

#Preview {
    HeaderView(user: User(name: "John Doe"))
        .previewLayout(.sizeThatFits)
}

