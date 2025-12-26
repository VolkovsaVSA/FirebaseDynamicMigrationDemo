//
//  FirebaseConfigView.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Firebase configuration settings screen.
//

import SwiftUI
import FirebaseCore

struct FirebaseConfigView: View {
    
    @State private var selectedConfig: FBConfigurationType = .production
    @State private var isLoading: Bool = false
    @State private var statusMessage: String?
    @State private var currentProjectId: String = ""
    @State private var migrationModeEnabled: Bool = false
    
    var body: some View {
        Form {
            // Section: Current state
            Section {
                LabeledContent("Project ID", value: currentProjectId.isEmpty ? "Not connected" : currentProjectId)
                LabeledContent("Configuration", value: FirebaseConfigurationManager.shared.getCurrentConfiguration().displayName)
                
                HStack {
                    Circle()
                        .fill(FirebaseApp.app() != nil ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(FirebaseApp.app() != nil ? "Connected" : "Not connected")
                }
            } header: {
                Text("Current State")
            }
            
            // Section: All Firebase Apps
            Section {
                if let defaultApp = FirebaseApp.app() {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Default App")
                                .font(.headline)
                            Text(defaultApp.options.projectID ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                if let migrationApp = FirebaseApp.app(name: FBConfigurationType.migration.firebaseAppName) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Migration App")
                                .font(.headline)
                            Text(migrationApp.options.projectID ?? "Unknown")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
            } header: {
                Text("Active Firebase Apps")
            }
            
            // Section: Configuration switching
            Section {
                #if DEBUG
                Picker("Configuration", selection: $selectedConfig) {
                    ForEach([FBConfigurationType.production, .sandbox, .migration], id: \.self) { config in
                        Text(config.displayName).tag(config)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedConfig) { _, newValue in
                    switchConfiguration(to: newValue)
                }
                #else
                Text("Switching is only available in DEBUG builds")
                    .foregroundColor(.secondary)
                #endif
            } header: {
                Text("Configuration Switching")
            } footer: {
                Text("Warning: Switching configuration will reset all Firebase sessions")
            }
            
            // Section: Migration Mode
            Section {
                Toggle("Migration Mode", isOn: $migrationModeEnabled)
                    .onChange(of: migrationModeEnabled) { _, newValue in
                        toggleMigrationMode(enabled: newValue)
                    }
            } header: {
                Text("Migration Mode")
            } footer: {
                Text("Enables parallel connection to NewApp Firebase project for data migration")
            }
            
            // Section: Status
            if let status = statusMessage {
                Section {
                    Text(status)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Status")
                }
            }
        }
        .navigationTitle("Firebase Config")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            updateCurrentState()
        }
    }
    
    // MARK: - Private Methods
    
    private func updateCurrentState() {
        if let app = FirebaseApp.app() {
            currentProjectId = app.options.projectID ?? "Unknown"
        } else {
            currentProjectId = ""
        }
        
        selectedConfig = FirebaseConfigurationManager.shared.getCurrentConfiguration()
        migrationModeEnabled = FirebaseApp.app(name: FBConfigurationType.migration.firebaseAppName) != nil
    }
    
    private func switchConfiguration(to config: FBConfigurationType) {
        isLoading = true
        statusMessage = "Switching to \(config.displayName)..."
        
        FirebaseConfigurationManager.shared.switchConfiguration(to: config)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateCurrentState()
            statusMessage = "Switched to \(config.displayName)"
            isLoading = false
        }
    }
    
    private func toggleMigrationMode(enabled: Bool) {
        isLoading = true
        statusMessage = enabled ? "Enabling Migration Mode..." : "Disabling Migration Mode..."
        
        FirebaseConfigurationManager.shared.setMigrationMode(enabled)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            updateCurrentState()
            statusMessage = enabled ? "Migration Mode enabled" : "Migration Mode disabled"
            isLoading = false
        }
    }
}

#Preview {
    NavigationStack {
        FirebaseConfigView()
    }
}
