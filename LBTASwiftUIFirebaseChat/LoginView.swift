//
//  ContentView.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 15.09.2024.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseStorage

// Main login view that handles both login and account creation.
struct LoginView: View {
    
    // Callback function that runs after successful login or account creation.
    let didCompleteLoginProcess: () -> ()
    
    // State variables to track the login mode, email, and password input.
    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    
    // State to control whether the image picker is shown.
    @State private var shouldShowImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                
                VStack(spacing:16) {
                    // Picker to switch between Login and Create Account modes.
                    Picker(selection: $isLoginMode, label:
                            Text("Picker here")) {
                        Text("Login")
                            .tag(true)
                        Text("Create Account")
                            .tag(false)
                    }.pickerStyle(SegmentedPickerStyle())
                        .padding()
                        
                    // Display image picker button if in account creation mode.
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            
                            VStack {
                                
                                if let image = self.image {
                                    // If an image is selected, display it.
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 128, height: 128)
                                        .cornerRadius(64)
                                    
                                } else {
                                    // Default user icon if no image is selected.
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(Color(UIColor(red: 38/255, green: 66/255, blue: 90/255, alpha: 1.0)))
                                    
                                }
                                
                            }
                            .overlay(RoundedRectangle(cornerRadius: 64)
                                .stroke(Color.primary, lineWidth: 0.5))
                        }
                    } else {
                        // Display welcome message in login mode.
                        Text("Chatty World")
                            .padding(9)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(UIColor(red: 38/255, green: 66/255, blue: 90/255, alpha: 1.0)))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                            .multilineTextAlignment(.center)
                    }
                    
                    // Input fields for email and password.
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .frame(width: 350, height: 28)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground)) // Light gray background color
                            .cornerRadius(34)
                            .shadow(radius: 5)
                            .foregroundColor(.primary) // Use system text color

                        SecureField("Password", text: $password)
                            .frame(width: 350, height: 28)
                            .padding(8)
                            .background(Color(UIColor.secondarySystemBackground)) // Light gray background color
                            .cornerRadius(34)
                            .shadow(radius: 5)
                            .foregroundColor(.primary) // Use system text color
                    }
                    .padding(5)
                    Spacer()
                    
                    // Button to log in or create a new account.
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Log In" : "Create Account")
                                .foregroundColor(.white)
                                .frame(width: 130, height: 28)
                                .padding(8)
                                .background(Color(UIColor(red: 38/255, green: 66/255, blue: 90/255, alpha: 1.0)))
                                .cornerRadius(34)
                                .shadow(radius: 5)
                            Spacer()
                        }
                    }
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                    .padding()
                }
                .navigationTitle(isLoginMode ? "Log In" : "Create Account" )
                .background(Color(.init(white:0, alpha: 0.05 ))
                    .ignoresSafeArea())
                
                // Footer text.
                Text("© 2024 Emre Tatlıcı. All rights reserved.")
                    .font(.footnote)
                    .foregroundColor(Color(.gray))
                    .padding(.top,150)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil) {
            ImagePicker(selectedImage: $image )
        }
    }
    
    @State var image: UIImage?
    
    // Decides whether to log in or create a new account based on the current mode.
    private func handleAction() {
        if isLoginMode {
            loginUser()
        } else {
            createNewAccount()
        }
    }
    
    // Function to log in an existing user using Firebase authentication.
    private func loginUser() {
        Auth.auth().signIn(withEmail: email, password: password) {
            result, err in
            if let err = err {
                print("Failed to login user:", err)
                self.loginStatusMessage = "Failed to login user: \(err)"
                return
            }
            print("Successfully logged in as user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully logged in as user: \(result?.user.uid ?? "")"
        
            self.didCompleteLoginProcess()
        }
    }
    
    @State var loginStatusMessage = ""
    
    // Function to create a new account in Firebase.
    private func createNewAccount() {
        if self.image == nil {
            self.loginStatusMessage = "You must select an avatar image"
            return
        }
        
        Auth.auth().createUser(withEmail: self.email, password: self.password) {
            result, error in
            if let err = error {
                print("Failed to create user:", err)
                self.loginStatusMessage = "Failed to create user: \(err)"
                return
            }
            
            print("Successfully created user: \(result?.user.uid ?? "")")
            
            self.loginStatusMessage = "Successfully created user: \(result?.user.uid ?? "")"
            
            self.persistImageToStorage()
        }
    }
    
    // Function to upload the user's profile image to Firebase Storage.
    private func persistImageToStorage() {
        let filename = UUID().uuidString
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let ref = FirebaseStorage.Storage.storage().reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else {return}
        
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err)"
                return
            }
            ref.downloadURL {url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err)"
                    return
                }
                self.loginStatusMessage = "Successfully stored image url: \(url?.absoluteString ?? "")"
                print(url?.absoluteString)
                
                guard let url = url else { return }
                storeUserInformation(imageProfileUrl: url)
            }
        }
    }
    
    // Function to store user information (email, uid, and profile image URL) in Firestore.
    private func storeUserInformation(imageProfileUrl: URL) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userData = ["email":self.email, "uid": uid, "profileImageUrl":imageProfileUrl.absoluteString]
        
        Firestore.firestore().collection("users")
            .document(uid).setData(userData) { err in
                if let err = err {
                    print(err)
                    self.loginStatusMessage = "\(err)"
                    return
                }
                
                print("Success")
                
                self.didCompleteLoginProcess()
            }
    }
}

struct ContentView_Previews1: PreviewProvider {
    static var previews: some View {
        LoginView(didCompleteLoginProcess: {

        })
    }
}
