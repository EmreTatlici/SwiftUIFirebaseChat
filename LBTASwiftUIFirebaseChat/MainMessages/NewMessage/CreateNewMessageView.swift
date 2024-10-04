//
//  NewMessageView.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 19.09.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SDWebImageSwiftUI

/// ViewModel responsible for fetching all users from Firestore and storing them in a list.
/// It handles the logic of fetching users while ensuring that the current logged-in user is excluded.
class CreateNewMessageViewModel: ObservableObject {
    
    /// Published array that contains all chat users fetched from Firestore.
    @Published var users = [ChatUser]()
    
    /// Published string to handle and display error messages during data fetching.
    @Published var errorMessage = ""
    
    /// Initializes the view model and triggers the fetch operation for all users.
    init() {
        fetchAllUsers()
    }
    
    /// Fetches all users from the Firestore "users" collection.
    /// Excludes the currently logged-in user from the list of users.
    /// If there's an error, it updates the `errorMessage` with the error details.
    private func fetchAllUsers() {
        Firestore.firestore().collection("users")
            .getDocuments { documentsSnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch users: \(error)"
                    print("Failed to fetch users: \(error)")
                    return
                }
                
                // Iterates over all fetched user documents and adds them to the users array
                documentsSnapshot?.documents.forEach({ snapshot in
                    let data = snapshot.data()
                    let user = ChatUser(data: data)
                    
                    // Ensures the logged-in user is not included in the user list
                    if user.uid != Auth.auth().currentUser?.uid {
                        self.users.append(.init(data: data))
                    }
                })
                
            }
    }
}

/// View responsible for displaying a list of users to start a new message conversation.
/// When a user is selected, it triggers the parent view's logic to handle new message creation.
struct CreateNewMessageView: View {
    
    /// Closure to handle the action when a user is selected from the list.
    let didSelectNewUser: (ChatUser) -> ()
    
    /// Presentation mode environment to dismiss the view when needed.
    @Environment(\.presentationMode) var presentationMode
    
    /// ViewModel instance to handle user fetching and storing logic.
    @ObservedObject var vm = CreateNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                // Displays any error message encountered during user fetching
                Text(vm.errorMessage)
                
                // Iterates over the fetched users and displays them in a list
                ForEach(vm.users) { user in
                    Button {
                        // When a user is selected, dismiss the view and call the didSelectNewUser closure
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                        
                    } label: {
                        // HStack containing the user's profile image and email
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50)
                                    .stroke(Color(.label), lineWidth: 1))
                            
                            // Display the user's email
                            Text(user.email)
                                .foregroundColor(Color(.label))
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.vertical)
                    }
                }
                
            }
            .navigationTitle("New Message")
            .toolbar {
                // Cancel button to dismiss the view without selecting a user
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                            .foregroundColor(Color(UIColor(red: 50/255, green: 100/255, blue: 90/255, alpha: 1.0)))
                    }
                }
            }
        }
    }
}

#Preview {
    // Preview for CreateNewMessageView, this can be used for development testing
    MainMessageView()
}
