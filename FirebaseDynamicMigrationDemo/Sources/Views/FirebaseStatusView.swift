//
//  FirebaseStatusView.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Displays current Firebase connection status.
//

import SwiftUI
import FirebaseCore

struct FirebaseStatusView: View {
    
    @State private var projectID: String = "Not connected"
    @State private var configType: String = "Unknown"
    @State private var isConnected: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                
                Text(isConnected ? "Connected" : "Not connected")
                    .font(.headline)
            }
            
            if isConnected {
                LabeledContent("Project ID", value: projectID)
                    .font(.caption)
                
                LabeledContent("Configuration", value: configType)
                    .font(.caption)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            updateStatus()
        }
    }
    
    private func updateStatus() {
        if let app = FirebaseApp.app() {
            isConnected = true
            projectID = app.options.projectID ?? "Unknown"
            configType = FirebaseConfigurationManager.shared.getCurrentConfiguration().displayName
        } else {
            isConnected = false
            projectID = "Not connected"
            configType = "Unknown"
        }
    }
}

#Preview {
    FirebaseStatusView()
        .padding()
}
