//
//  User.swift
//  workout
//
//  Created by Noa Mandorf on 12/5/25.
//

import Foundation

struct User: Identifiable {
    let id: String
    let name: String
    let profileImageName: String?
    
    init(id: String = UUID().uuidString, name: String, profileImageName: String? = nil) {
        self.id = id
        self.name = name
        self.profileImageName = profileImageName
    }
}


