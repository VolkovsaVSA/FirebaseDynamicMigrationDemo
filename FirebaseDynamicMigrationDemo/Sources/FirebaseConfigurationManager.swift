//
//  FirebaseConfigurationManager.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Manager for Firebase configurations.
//
//  This class solves a key task: allows one application to work
//  with multiple Firebase projects simultaneously or switch between them.
//

import Foundation
import FirebaseCore

/// Firebase configuration manager.
///
/// Main capabilities:
/// 1. Switching between Production/Sandbox configurations
/// 2. Enabling "migration mode" for parallel work with two projects
/// 3. Validation of loaded configurations
///
/// ## Architecture
///
/// Firebase supports simultaneous work with multiple projects through named Apps:
/// - **Default App** (`FirebaseApp.app()`): main project (Production or Sandbox)
/// - **Named App** (`FirebaseApp.app(name:)`): additional project (Migration)
///
/// ## Usage
///
/// ```swift
/// // On app launch
/// let config = FirebaseConfigurationManager.shared.getCurrentConfiguration()
/// FirebaseConfigurationManager.shared.switchConfiguration(to: config)
///
/// // For data migration
/// FirebaseConfigurationManager.shared.setMigrationMode(true)
/// // ... perform migration ...
/// FirebaseConfigurationManager.shared.setMigrationMode(false)
/// ```
final class FirebaseConfigurationManager {
    
    // MARK: - Singleton
    
    static let shared = FirebaseConfigurationManager()
    
    private init() {}
    
    // MARK: - Properties
    
    /// Current active configuration.
    ///
    /// Saved in UserDefaults for restoration after restart.
    private(set) var currentConfiguration: FBConfigurationType = .defaultForCurrentBuild
    
    /// Key for saving current configuration in UserDefaults.
    private let configurationKey = "firebase_current_configuration"
    
    /// Indicates if Firebase is properly configured.
    /// Use this to check before performing Firebase operations.
    private(set) var isFirebaseConfigured: Bool = false
    
    /// Last configuration error message (if any).
    private(set) var lastConfigurationError: String?
    
    // MARK: - Public Methods
    
    /// Returns current configuration.
    ///
    /// In RELEASE builds always returns Production, ignoring saved value.
    /// This is protection against accidentally using Sandbox in production.
    func getCurrentConfiguration() -> FBConfigurationType {
        #if DEBUG
        // In DEBUG mode read from UserDefaults
        if let savedConfig = UserDefaults.standard.string(forKey: configurationKey),
           let config = FBConfigurationType(rawValue: savedConfig) {
            return config
        }
        return .sandbox  // Default for DEBUG
        #else
        // In RELEASE always Production!
        return .production
        #endif
    }
    
    /// Switches active Firebase configuration.
    ///
    /// IMPORTANT: Switching configuration resets:
    /// - All active Firestore listeners
    /// - Firestore cache
    /// - Authentication state (user will be logged out!)
    ///
    /// - Parameter type: Configuration type to activate
    func switchConfiguration(to type: FBConfigurationType) {
        print("FirebaseConfigurationManager: Switching to \(type.displayName)")
        
        // Save choice (only in DEBUG)
        #if DEBUG
        UserDefaults.standard.set(type.rawValue, forKey: configurationKey)
        #endif
        
        // Load configuration
        loadFirebaseConfig(type: type)
        currentConfiguration = type
    }
    
    /// Enables or disables migration mode.
    ///
    /// In migration mode the application connects to an additional Firebase project
    /// (NewAppFB) to write/read migration data, while maintaining connection
    /// to the main project.
    ///
    /// ## How it works
    ///
    /// When migration mode is enabled:
    /// - Default App stays connected to Production/Sandbox
    /// - Named App "MigrationFirebaseApp" is created for NewAppFB
    /// - Firestore for migration is obtained via `Firestore.firestore(app: migrationApp)`
    ///
    /// - Parameter enabled: true to enable migration mode
    func setMigrationMode(_ enabled: Bool) {
        if enabled {
            print("FirebaseConfigurationManager: Enabling Migration Mode")
            loadFirebaseConfig(type: .migration)
        } else {
            print("FirebaseConfigurationManager: Disabling Migration Mode")
            // Delete migration app if it exists
            if let migrationApp = FirebaseApp.app(name: FBConfigurationType.migration.firebaseAppName) {
                migrationApp.delete { success in
                    if success {
                        print("Migration app deleted successfully")
                    }
                }
            }
        }
    }
    
    /// Returns Firestore for specified configuration.
    ///
    /// Use this method to get the correct Firestore instance:
    /// - For regular operations: `getFirestore(for: .production)` or without parameter
    /// - For migration: `getFirestore(for: .migration)`
    ///
    /// - Parameter type: Configuration type
    /// - Returns: Firestore instance or nil if configuration is not loaded
    func getFirestore(for type: FBConfigurationType = .production) -> Any? {
        // Note: returning Any? to avoid dependency on FirebaseFirestore
        // In real code use: Firestore.firestore(app: app)
        guard let app = type.firebaseApp else {
            print("Warning: Firebase app not configured for \(type.displayName)")
            return nil
        }
        return app // In real code: return Firestore.firestore(app: app)
    }
    
    // MARK: - Private Methods
    
    /// Loads Firebase configuration from plist file.
    ///
    /// Loading process:
    /// 1. Find plist file in Bundle
    /// 2. Create FirebaseOptions from plist
    /// 3. Validate PROJECT_ID and GOOGLE_APP_ID
    /// 4. Clean up existing configurations (if needed)
    /// 5. Configure Firebase App
    private func loadFirebaseConfig(type: FBConfigurationType) {
        print("Loading config: \(type.plistName)")
        
        // Reset state
        lastConfigurationError = nil
        
        // 1. Find plist file
        guard let plistPath = Bundle.main.path(forResource: type.plistName, ofType: "plist") else {
            let error = "\(type.plistName).plist not found! Add your Firebase configuration file."
            print("ERROR: \(error)")
            lastConfigurationError = error
            isFirebaseConfigured = false
            return
        }
        
        // 2. Create FirebaseOptions
        guard let options = FirebaseOptions(contentsOfFile: plistPath) else {
            let error = "Failed to parse \(type.plistName).plist"
            print("ERROR: \(error)")
            lastConfigurationError = error
            isFirebaseConfigured = false
            return
        }
        
        // 3. Validate configuration - check for placeholder values
        let googleAppId = options.googleAppID
        // Check if it's a placeholder value (contains YOUR_ or placeholder patterns)
        if googleAppId.contains("YOUR_") ||
           googleAppId.contains("your-") ||
           googleAppId == "1:YOUR_PROJECT_NUMBER:ios:YOUR_APP_ID" ||
           googleAppId.hasPrefix("1:YOUR_") {
            let error = "Invalid GOOGLE_APP_ID in \(type.plistName).plist. Please replace with your real Firebase configuration from Firebase Console."
            print("ERROR: \(error)")
            print("HINT: Download GoogleService-Info.plist from https://console.firebase.google.com/")
            lastConfigurationError = error
            isFirebaseConfigured = false
            return
        }
        
        // Check PROJECT_ID for placeholder values
        if let projectId = options.projectID {
            print("Project ID: \(projectId)")
            
            if projectId.contains("your-") || projectId.contains("YOUR_") {
                let error = "Invalid PROJECT_ID in \(type.plistName).plist. Please use real Firebase configuration."
                print("ERROR: \(error)")
                lastConfigurationError = error
                isFirebaseConfigured = false
                return
            }
            
            // Warn about ID mismatch (but don't fail)
            if projectId != type.expectedProjectId && !type.expectedProjectId.contains("your-") {
                print("WARNING: Project ID mismatch!")
                print("   Expected: \(type.expectedProjectId)")
                print("   Got: \(projectId)")
            }
        }
        
        // 4. Clean up existing configurations
        cleanupExistingConfigurations(for: type)
        
        // 5. Configure Firebase
        configureFirebaseApp(type: type, options: options)
    }
    
    /// Cleans up existing Firebase configurations before switching.
    ///
    /// CRITICALLY IMPORTANT!
    ///
    /// Firebase SDK does not allow calling `configure()` again without deleting
    /// the existing application. Attempting to do so will cause a crash!
    ///
    /// ## Cleanup logic
    ///
    /// - For Production/Sandbox (default apps): delete default app
    /// - For Migration (named app): delete only migration app
    ///
    /// - Parameter type: Configuration type we're about to load
    private func cleanupExistingConfigurations(for type: FBConfigurationType) {
        if type.usesDefaultApp {
            // For default app: delete existing default app
            if let existingApp = FirebaseApp.app() {
                print("Deleting existing default app...")
                
                // Synchronous deletion (blocks thread!)
                let semaphore = DispatchSemaphore(value: 0)
                existingApp.delete { _ in
                    semaphore.signal()
                }
                semaphore.wait()
                
                print("Default app deleted")
            }
        } else {
            // For named app: delete only this named app
            if let existingApp = FirebaseApp.app(name: type.firebaseAppName) {
                print("Deleting existing \(type.firebaseAppName)...")
                
                let semaphore = DispatchSemaphore(value: 0)
                existingApp.delete { _ in
                    semaphore.signal()
                }
                semaphore.wait()
                
                print("\(type.firebaseAppName) deleted")
            }
        }
    }
    
    /// Configures Firebase App.
    ///
    /// - For default apps: uses `FirebaseApp.configure(options:)`
    /// - For named apps: uses `FirebaseApp.configure(name:options:)`
    ///
    /// - Parameters:
    ///   - type: Configuration type
    ///   - options: Firebase options from plist file
    private func configureFirebaseApp(type: FBConfigurationType, options: FirebaseOptions) {
        if type.usesDefaultApp {
            print("Configuring default Firebase app...")
            FirebaseApp.configure(options: options)
        } else {
            print("Configuring named Firebase app: \(type.firebaseAppName)")
            FirebaseApp.configure(name: type.firebaseAppName, options: options)
        }
        
        // Check result
        if let app = type.firebaseApp {
            print("Firebase configured successfully: \(app.options.projectID ?? "unknown")")
            isFirebaseConfigured = true
            lastConfigurationError = nil
        } else {
            let error = "Firebase configuration failed - app not created"
            print("ERROR: \(error)")
            lastConfigurationError = error
            isFirebaseConfigured = false
        }
    }
}
