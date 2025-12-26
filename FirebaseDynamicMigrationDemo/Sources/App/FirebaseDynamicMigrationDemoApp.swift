//
//  FirebaseDynamicMigrationDemoApp.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Demo application for dynamic Firebase project switching.
//

import SwiftUI
import FirebaseCore

@main
struct FirebaseDynamicMigrationDemoApp: App {
    
    @State private var firebaseError: String?
    
    // Initialize Firebase on app launch
    init() {
        setupFirebase()
    }
    
    var body: some Scene {
        WindowGroup {
            if let error = FirebaseConfigurationManager.shared.lastConfigurationError {
                FirebaseSetupRequiredView(errorMessage: error)
            } else {
                ContentView()
            }
        }
    }
    
    private func setupFirebase() {
        let configManager = FirebaseConfigurationManager.shared
        let currentConfig = configManager.getCurrentConfiguration()
        
        print("Configuring Firebase: \(currentConfig.displayName)")
        configManager.switchConfiguration(to: currentConfig)
        
        if configManager.isFirebaseConfigured, let app = FirebaseApp.app() {
            print("Firebase ready. Project: \(app.options.projectID ?? "unknown")")
        } else {
            print("Firebase not configured. App will show setup instructions.")
        }
    }
}

// MARK: - Firebase Setup Required View

/// View shown when Firebase is not properly configured.
/// This allows the app to run without crashing even with placeholder plist values.
struct FirebaseSetupRequiredView: View {
    let errorMessage: String
    
    private let instructions: [SetupInstruction] = [
        SetupInstruction(text: "Go to Firebase Console"),
        SetupInstruction(text: "Create a new project (or use existing)"),
        SetupInstruction(text: "Add an iOS app to the project"),
        SetupInstruction(text: "Download GoogleService-Info.plist"),
        SetupInstruction(text: "Rename it to GoogleService-Info-Sandbox.plist"),
        SetupInstruction(text: "Replace the file in Resources/Firebase/"),
        SetupInstruction(text: "Rebuild and run the app")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                        .padding(.top, 40)
                    
                    // Title
                    Text("Firebase Setup Required")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Error message
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Setup Instructions:")
                            .font(.headline)
                        
                        ForEach(Array(instructions.enumerated()), id: \.element.id) { index, instruction in
                            InstructionRow(number: index + 1, text: instruction.text)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Link to Firebase Console
                    Link(destination: URL(string: "https://console.firebase.google.com/")!) {
                        HStack {
                            Image(systemName: "arrow.up.right.square")
                            Text("Open Firebase Console")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    // Note about demo
                    Text("This demo project includes placeholder plist files. You must replace them with real Firebase configuration files to use the app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationTitle("Setup Required")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Models

struct SetupInstruction: Identifiable {
    let id = UUID()
    let text: String
}

// MARK: - Subviews

struct InstructionRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
                .frame(width: 24, alignment: .trailing)
            
            Text(text)
                .font(.body)
        }
    }
}

#Preview("Setup Required") {
    FirebaseSetupRequiredView(errorMessage: "Invalid GOOGLE_APP_ID in GoogleService-Info-Sandbox.plist. Please replace with your real Firebase configuration.")
}
