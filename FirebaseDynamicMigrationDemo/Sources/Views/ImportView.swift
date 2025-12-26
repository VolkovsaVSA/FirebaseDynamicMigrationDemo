//
//  ImportView.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Data import screen for NewApp.
//

import SwiftUI

struct ImportView: View {
    
    @StateObject private var viewModel = ImportViewModel()
    
    var body: some View {
        Form {
            // Section: User ID for import
            Section {
                TextField("User ID (email or ID)", text: $viewModel.userId)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } header: {
                Text("User Identifier")
            } footer: {
                Text("Enter the same ID that was used during migration in OldApp")
            }
            
            // Section: Import button
            Section {
                Button {
                    viewModel.importData()
                } label: {
                    HStack {
                        Spacer()
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        } else {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Import Data")
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.userId.isEmpty || viewModel.isLoading)
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
            
            // Section: Imported data
            if let data = viewModel.importedData {
                Section {
                    if let name = data["name"] as? String {
                        LabeledContent("Name", value: name)
                    }
                    if let email = data["email"] as? String {
                        LabeledContent("Email", value: email)
                    }
                    if let role = data["role"] as? String {
                        LabeledContent("Role", value: role)
                    }
                    
                    if let settings = data["settings"] as? [String: Any] {
                        if let theme = settings["theme"] as? String {
                            LabeledContent("Theme", value: theme)
                        }
                        if let language = settings["language"] as? String {
                            LabeledContent("Language", value: language)
                        }
                        if let notifications = settings["notifications"] as? Bool {
                            LabeledContent("Notifications", value: notifications ? "On" : "Off")
                        }
                    }
                } header: {
                    Text("Imported Data")
                }
            }
        }
        .navigationTitle("Data Import")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ImportView()
    }
}
