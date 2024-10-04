//  ChatLogView.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 23.09.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

// Constants used for Firebase document keys
struct FirebaseConstants {
    static let fromId = "fromId"
    static let toId = "toId"
    static let text = "text"
    static let timestamp = "timestamp"
    static let profileImageUrl = "profileImageUrl"
    static let email = "email"
}

// Model representing a chat message
struct ChatMessage: Identifiable {
    var id: String { documentId }
    
    let documentId: String
    let fromId, toId, text: String
    
    // Initializes the ChatMessage with data from Firestore
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.fromId = data[FirebaseConstants.fromId] as? String ?? ""
        self.toId = data[FirebaseConstants.toId] as? String ?? ""
        self.text = data[FirebaseConstants.text] as? String ?? ""
    }
}

// ViewModel to manage chat log functionality
class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    
    let chatUser: ChatUser?
    
    // Initializes the ViewModel and fetches chat messages
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    
    // Fetches chat messages from Firestore and listens for real-time updates
    private func fetchMessages() {
        guard let fromId = Auth.auth().currentUser?.uid,
              let toId = chatUser?.uid else { return }

        Firestore.firestore()
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: FirebaseConstants.timestamp)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    return
                }
                
                // Processes newly added messages
                querySnapshot?.documentChanges.forEach { change in
                    if change.type == .added {
                        let data = change.document.data()
                        self.chatMessages.append(ChatMessage(documentId: change.document.documentID, data: data))
                    }
                }
                DispatchQueue.main.async {
                    self.count += 1 // Increments count to trigger UI update
                }
            }
    }
    
    // Handles sending a new chat message
    func handleSend() {
        guard let fromId = Auth.auth().currentUser?.uid,
              let toId = chatUser?.uid else { return }
        
        let messageData: [String: Any] = [
            FirebaseConstants.fromId: fromId,
            FirebaseConstants.toId: toId,
            FirebaseConstants.text: chatText,
            FirebaseConstants.timestamp: Timestamp()
        ]
        
        // Stores the message for the sender
        let document = Firestore.firestore()
            .collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
            self.persistRecentMessage() // Persists the recent message
            self.chatText = "" // Resets the chat input field
            self.count += 1 // Increments count to trigger UI update
        }
        
        // Stores the message for the recipient
        let recipientMessageDocument = Firestore.firestore()
            .collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                return
            }
        }
    }
    
    // Persists the recent message to the 'recent_messages' collection
    private func persistRecentMessage() {
        guard let chatUser = chatUser else { return }
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = Firestore.firestore()
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        let data = [
            FirebaseConstants.timestamp: Timestamp(),
            FirebaseConstants.text: self.chatText,
            FirebaseConstants.fromId: uid,
            FirebaseConstants.toId: toId,
            FirebaseConstants.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstants.email: chatUser.email
        ] as [String: Any]
        
        document.setData(data) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                return
            }
        }
    }
}

// View displaying the chat log
struct ChatLogView: View {
    let chatUser: ChatUser?
    @ObservedObject var vm: ChatLogViewModel
    
    // Initializes the view with the selected chat user
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = ChatLogViewModel(chatUser: chatUser)
    }
    
    var body: some View {
        ZStack {
            messagesView // Displays the chat messages
            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage) // Displays error message if any
                    .foregroundColor(.red)
            }
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // View for displaying messages in a scrollable view
    private var messagesView: some View {
        VStack {
            ScrollView {
                ScrollViewReader { scrollViewProxy in
                    VStack {
                        ForEach(vm.chatMessages) { message in
                            MessageView(message: message) // Renders each chat message
                        }
                        HStack { Spacer() }
                            .id("Empty") // Anchor for scrolling
                    }
                    .onReceive(vm.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            scrollViewProxy.scrollTo("Empty", anchor: .bottom) // Scrolls to the latest message
                        }
                    }
                }
            }
            .background(Color(.init(white: 0.95, alpha: 1))) // Background color for messages
            .safeAreaInset(edge: .bottom) {
                chatBottomBar // Displays the message input field
                    .background(Color(.systemBackground).ignoresSafeArea())
            }
        }
    }
    
    // Bottom bar for sending messages
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle") // Icon for attaching photos
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            
            TextEditor(text: $vm.chatText) // Input field for chat text
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.gray, lineWidth: 1))
                .opacity(vm.chatText.isEmpty ? 0.5 : 1) // Adjusts opacity based on input state
                .frame(height: 40)
            
            Button {
                vm.handleSend() // Sends the message
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(UIColor(red: 38/255, green: 66/255, blue: 90/255, alpha: 1.0))) // Background color for send button
            .cornerRadius(20)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// View for displaying an individual message
struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.fromId == Auth.auth().currentUser?.uid {
                Spacer()
                messageBubble(text: message.text, backgroundColor: .blue, textColor: .white) // Outgoing message bubble
            } else {
                messageBubble(text: message.text, backgroundColor: Color(.lightGray), textColor: .black) // Incoming message bubble
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    // Creates a styled message bubble
    private func messageBubble(text: String, backgroundColor: Color, textColor: Color) -> some View {
        Text(text)
            .foregroundColor(textColor)
            .padding()
            .background(backgroundColor)
            .cornerRadius(8)
    }
}

// Preview for the ChatLogView
#Preview {
    NavigationView {
        MainMessageView()
    }
}
