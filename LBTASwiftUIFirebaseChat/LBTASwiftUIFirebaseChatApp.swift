//
//  LBTASwiftUIFirebaseChatApp.swift
//  LBTASwiftUIFirebaseChat
//
//  Created by Mustafa Emre Tatlıcı on 15.09.2024.
//

import SwiftUI
import Firebase

@main
struct LBTASwiftUIFirebaseChatApp: App {
    
    // Configure Firebase when the app launches
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView(didCompleteLoginProcess: {
                
            })
        }
    }
}
