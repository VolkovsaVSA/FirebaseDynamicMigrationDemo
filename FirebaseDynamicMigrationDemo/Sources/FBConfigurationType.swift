//
//  FBConfigurationType.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Firebase configuration types.
//
//  IMPORTANT: Before using, add real GoogleService-Info-*.plist files
//  to the Resources/Firebase/ folder of your project!
//

import Foundation
import FirebaseCore

/// Firebase configuration types.
///
/// Each type corresponds to a separate Firebase project and has its own plist file:
/// - `production`: Production project (OldAppFB or NewAppFB)
/// - `sandbox`: Sandbox for development (SandboxFB)
/// - `migration`: NewApp project for data migration (NewAppFB)
///
/// Key features:
/// - Production and Sandbox use the **default** Firebase App
/// - Migration uses a **named** Firebase App ("MigrationFirebaseApp")
/// - This allows working with two Firebase projects simultaneously!
enum FBConfigurationType: String, CaseIterable {
    case production = "Production"
    case sandbox = "Sandbox"
    case migration = "Migration"
    
    // MARK: - Plist Configuration
    
    /// Plist file name without extension.
    ///
    /// All plist files have unique names to avoid conflicts:
    /// - GoogleService-Info-Production.plist
    /// - GoogleService-Info-Sandbox.plist
    /// - GoogleService-Info-Migration.plist
    var plistName: String {
        switch self {
        case .production:
            return "GoogleService-Info-Production"
        case .sandbox:
            return "GoogleService-Info-Sandbox"
        case .migration:
            return "GoogleService-Info-Migration"
        }
    }
    
    /// Expected PROJECT_ID for validation.
    ///
    /// REPLACE with real IDs of your Firebase projects!
    var expectedProjectId: String {
        switch self {
        case .production:
            // TODO: Replace with your production project ID
            return "your-production-project-id"
        case .sandbox:
            // TODO: Replace with your sandbox project ID
            return "your-sandbox-project-id"
        case .migration:
            // TODO: Replace with your NewApp project ID for migration
            return "your-migration-project-id"
        }
    }
    
    // MARK: - Firebase App Management
    
    /// Determines if this configuration uses the default Firebase App.
    ///
    /// - Production and Sandbox: use default app (one at a time)
    /// - Migration: uses named app (can work in parallel with default)
    var usesDefaultApp: Bool {
        switch self {
        case .production, .sandbox:
            return true
        case .migration:
            return false
        }
    }
    
    /// Firebase App name for named configurations.
    ///
    /// Used only for `.migration` - returns name for `FirebaseApp.configure(name:options:)`
    var firebaseAppName: String {
        switch self {
        case .production, .sandbox:
            // Default apps don't have a name
            return "[DEFAULT]"
        case .migration:
            return "MigrationFirebaseApp"
        }
    }
    
    /// Returns the corresponding FirebaseApp if it exists.
    ///
    /// - For production/sandbox: returns default app
    /// - For migration: returns named app
    var firebaseApp: FirebaseApp? {
        switch self {
        case .production, .sandbox:
            return FirebaseApp.app()
        case .migration:
            return FirebaseApp.app(name: firebaseAppName)
        }
    }
    
    // MARK: - Display
    
    /// Human-readable name for UI.
    var displayName: String {
        switch self {
        case .production:
            return "Production"
        case .sandbox:
            return "Sandbox"
        case .migration:
            return "Migration"
        }
    }
    
    // MARK: - Build Configuration
    
    /// Default configuration based on build type.
    ///
    /// In DEBUG builds Sandbox is used, in RELEASE - Production.
    /// This is standard practice for separating environments.
    static var defaultForCurrentBuild: FBConfigurationType {
        #if DEBUG
        return .sandbox
        #else
        return .production
        #endif
    }
}
