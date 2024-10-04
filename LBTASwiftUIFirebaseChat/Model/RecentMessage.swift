//
//  RecentMessage.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 2.10.2024.
//

import Foundation
import Firebase

// Represents a recent message in the chat application
struct RecentMessage: Identifiable {
    // The unique identifier for the message, using the document ID
    var id: String { documentId }
    
    var documentId: String // The Firestore document ID for the message
    var email: String // The email of the user who sent the message
    var profileImageUrl: String // URL of the user's profile image
    var text: String // The content of the message
    var timestamp: Timestamp // Timestamp indicating when the message was sent
    var unreadMessagesCount: Int // Count of unread messages
    var chatUser: ChatUser? // An optional ChatUser object representing the user

    // Initializes a RecentMessage object with a document ID and data dictionary
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.email = data["email"] as? String ?? "" // Safely extracts the email or defaults to an empty string
        self.profileImageUrl = data["profileImageUrl"] as? String ?? "" // Safely extracts the profile image URL or defaults to an empty string
        self.text = data["text"] as? String ?? "" // Safely extracts the message text or defaults to an empty string
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp(date: Date()) // Safely extracts the timestamp or defaults to the current date
        self.unreadMessagesCount = data["unreadMessagesCount"] as? Int ?? 0 // Safely extracts the unread messages count or defaults to 0
        self.chatUser = nil // Initializes the chatUser property as nil
    }

    // Increments the count of unread messages by one
    mutating func incrementUnreadCount() {
        self.unreadMessagesCount += 1
    }
}
