//
//  ContentView.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Main screen with navigation.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                // Section: Current Firebase status
                Section {
                    FirebaseStatusView()
                } header: {
                    Text("Firebase Status")
                }
                
                // Section: Data migration (for OldApp)
                Section {
                    NavigationLink {
                        MigrationView()
                    } label: {
                        Label("Data Migration", systemImage: "arrow.right.circle.fill")
                    }
                } header: {
                    Text("OldApp -> NewApp")
                } footer: {
                    Text("Write data from OldApp to NewApp Firebase project")
                }
                
                // Section: Data import (for NewApp)
                Section {
                    NavigationLink {
                        ImportView()
                    } label: {
                        Label("Data Import", systemImage: "arrow.down.circle.fill")
                    }
                } header: {
                    Text("NewApp")
                } footer: {
                    Text("Read migrated data in NewApp")
                }
                
                // Section: Firebase settings
                Section {
                    NavigationLink {
                        FirebaseConfigView()
                    } label: {
                        Label("Firebase Configuration", systemImage: "gearshape.fill")
                    }
                } header: {
                    Text("Settings")
                }
            }
            .navigationTitle("Firebase Migration")
        }
    }
}

#Preview {
    ContentView()
}
