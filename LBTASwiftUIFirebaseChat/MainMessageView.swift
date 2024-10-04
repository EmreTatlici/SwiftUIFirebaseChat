//
//  MainMessageView.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 18.09.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage
import SDWebImageSwiftUI
import FirebaseFirestore

// ViewModel to manage the main messages screen, fetching the current user, recent messages, and handling user sign-out
class MainMessagesViewModel: ObservableObject {
    
    @Published var errorMessage = "" // Stores any error messages
    @Published var chatUser: ChatUser? // Stores the current chat user data
    
    // Initializes the ViewModel and sets the logged-out state
    init() {
        // Checks if the user is logged out
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = Auth.auth().currentUser?.uid == nil
        }
        
        // Fetches the current user and recent messages
        fetchCurrentUser()
        fetchRecentMessages()
    }
    
    @Published var recentMessages = [RecentMessage]() // Stores recent messages
    
    // Fetches the most recent messages from Firestore for the logged-in user
    private func fetchRecentMessages() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    return
                }
                
                // Handles message updates when there are changes in Firestore
                querySnapshot?.documentChanges.forEach({ change in
                    let docId = change.document.documentID
                    let data = change.document.data()
                    
                    let senderId = data["senderId"] as? String ?? ""
                    let receiverId = data["receiverId"] as? String ?? ""

                    // Updates or inserts a new message based on whether the user is the sender
                    if senderId == uid {
                        // If the user is the sender, you can update their message here
                    } else {
                        // The message is from the other person
                        if let index = self.recentMessages.firstIndex(where: { rm in
                            return rm.documentId == docId
                        }) {
                            // If the message exists, update it
                            self.recentMessages[index] = RecentMessage(documentId: docId, data: data)
                        } else {
                            // If it's a new message, insert it
                            self.recentMessages.insert(RecentMessage(documentId: docId, data: data), at: 0)
                        }
                    }
                })
            }
    }
    
    // Fetches the current user's data from Firestore
    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Could not find firebase uid"
            return
        }

        Firestore.firestore().collection("users")
            .document(uid)
            .getDocument { snapshot, error in
                if let error = error {
                    print("Failed to fetch current user:", error)
                    return
                }
                
                guard let data = snapshot?.data() else { return }
                self.chatUser = .init(data: data)
            }
    }
    
    @Published var isUserCurrentlyLoggedOut = false // Tracks if the user is logged out
    
    // Handles the sign-out process and updates the state accordingly
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? Auth.auth().signOut()
    }
}

struct MainMessageView: View {
    
    @State var shouldShowLogOutOptions = false // Controls the visibility of the logout options
    @State var shouldNavigateToChatLogView = false // Controls the navigation to the chat log view
    @ObservedObject private var vm = MainMessagesViewModel() // Observes the ViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Custom navigation bar and the list of recent messages
                customNavBar
                messagesView
                
                // Navigation link to the chat log view
                NavigationLink("", isActive: $shouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(newMessageButton, alignment: .bottom) // New message button overlay
            .navigationBarHidden(true) // Hides the default navigation bar
        }
    }
    
    // Custom navigation bar with user profile image and settings button
    private var customNavBar: some View {
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1))
                .shadow(radius: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(extractUsername(from: vm.chatUser?.email)) // Displays the user's email (extracted)
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online") // Displays online status
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
            }
            
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle() // Toggles the logout options
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Settings"), message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    vm.handleSignOut() // Calls the sign-out method
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
            LoginView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser() // Refetches the user after login
            })
        }
    }
    
    // Displays the list of recent messages
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack {
                    NavigationLink(destination: ChatLogView(chatUser: recentMessage.chatUser)) {
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .clipped()
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.black, lineWidth: 1))
                                .shadow(radius: 5)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text(recentMessage.email)
                                    .font(.system(size: 16, weight: .bold))
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            
                            Text(timeAgoSince(recentMessage.timestamp.dateValue())) // Shows the message timestamp
                                .font(.system(size: 14, weight: .semibold))
                            
                            // Displays unread message count, if any
                            if recentMessage.unreadMessagesCount > 0 {
                                Text("\(recentMessage.unreadMessagesCount)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.green)
                                    .clipShape(Circle())
                            }
                        }
                        .foregroundColor(Color(.label))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    // Converts a date to a "time ago" string format
    private func timeAgoSince(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let day = components.day, day > 0 {
            return day == 1 ? "1 d" : "\(day) d"
        }
        if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 h" : "\(hour) h"
        }
        if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 m" : "\(minute) m"
        }
        
        return "Just now"
    }
    
    @State var shouldShowNewMessageScreen = false // Controls visibility of the new message screen
    
    // Button to create a new message
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ New Message")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(20)
            .padding(.horizontal)
            .shadow(radius: 5)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                
                self.shouldNavigateToChatLogView.toggle()
                self.chatUser = user
            })
        }
    }
    
    
    @State var chatUser: ChatUser?
    
    // function that clears username
    private func extractUsername(from email: String?) -> String {
        guard let email = email else { return "" }
        if let range = email.range(of: "@") {
            return String(email[..<range.lowerBound])
        }
        return email
    }
}

struct MainMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessageView()
    }
}
