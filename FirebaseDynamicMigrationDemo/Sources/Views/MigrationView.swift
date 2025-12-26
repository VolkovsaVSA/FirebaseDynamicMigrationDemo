//
//  MigrationView.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Data migration screen from OldApp to NewApp.
//

import SwiftUI

struct MigrationView: View {
    
    @StateObject private var viewModel = MigrationViewModel()
    
    var body: some View {
        Form {
            // Section: User profile data
            Section {
                TextField("Name", text: $viewModel.userName)
                TextField("Email", text: $viewModel.userEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                TextField("Role", text: $viewModel.userRole)
            } header: {
                Text("User Profile")
            }
            
            // Section: Settings
            Section {
                Picker("Theme", selection: $viewModel.theme) {
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                    Text("System").tag("system")
                }
                
                Picker("Language", selection: $viewModel.language) {
                    Text("Russian").tag("ru")
                    Text("English").tag("en")
                }
                
                Toggle("Notifications", isOn: $viewModel.notifications)
            } header: {
                Text("Settings")
            }
            
            // Section: User ID for migration
            Section {
                TextField("User ID (email or ID)", text: $viewModel.userId)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } header: {
                Text("Migration Identifier")
            } footer: {
                Text("Use email or external ID. Do NOT use Firebase UID!")
            }
            
            // Section: Migration button
            Section {
                Button {
                    viewModel.startMigration()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Migrate Data")
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.userId.isEmpty || viewModel.isLoading)
            } footer: {
                Text("Data will be written to NewApp Firebase project")
            }
            
            // Section: Status
            if let status = viewModel.statusMessage {
                Section {
                    HStack {
                        Image(systemName: viewModel.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(viewModel.isSuccess ? .green : .red)
                        Text(status)
                    }
                } header: {
                    Text("Status")
                }
            }
        }
        .navigationTitle("Data Migration")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MigrationView()
    }
}
