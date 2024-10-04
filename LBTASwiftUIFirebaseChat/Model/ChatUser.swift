//
//  ChatUser.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 19.09.2024.
//

import Foundation

// The ChatUser struct represents a user in the chat application.
// It conforms to Identifiable, allowing SwiftUI to uniquely identify each user in a list.
struct ChatUser: Identifiable {
    
    // The unique identifier for the user, derived from their uid.
    var id: String { uid }
    
    // Properties for user ID, email, and profile image URL.
    let uid, email, profileImageUrl: String
    
    // Initializer that takes a dictionary of data and assigns values to the properties.
    init(data:[String: Any]) {
        // Extracts uid, email, and profileImageUrl from the dictionary, providing default values if they don't exist.
        self.uid = data["uid"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    }
    
}
