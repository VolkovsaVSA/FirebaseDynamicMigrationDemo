//
//  DataMigrationManager.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Manager for data migration from OldApp to NewApp.
//
//  This class is responsible for:
//  1. Collecting data from OldApp local storage
//  2. Connecting to NewApp Firebase project
//  3. Writing data to NewApp Firestore
//

import Foundation
import FirebaseCore
import FirebaseFirestore

/// Data migration manager.
///
/// ## Migration Process
///
/// 1. **Data collection**: Read data from UserDefaults, Keychain, CoreData, etc.
/// 2. **Enable Migration Mode**: Connect to NewApp Firebase project
/// 3. **Write to Firestore**: Save data to `users/{userId}` collection
/// 4. **Disable Migration Mode**: Disconnect from NewApp
///
/// ## Firestore Data Structure
///
/// ```
/// users/
///   - {userId}/
///       - name: "John Doe"
///       - email: "user@example.com"
///       - role: "user"
///       - createdAt: Timestamp
///       - migratedAt: Timestamp
///       - settings/
///           - theme: "dark"
///           - language: "en"
///           - notifications: true
/// ```
///
/// ## Usage Example
///
/// ```swift
/// DataMigrationManager.shared.migrateData(userId: "user@example.com") { result in
///     switch result {
///     case .success:
///         print("Migration complete!")
///     case .failure(let error):
///         print("Error: \(error)")
///     }
/// }
/// ```
final class DataMigrationManager {
    
    // MARK: - Singleton
    
    static let shared = DataMigrationManager()
    
    private init() {}
    
    // MARK: - Constants
    
    /// Firestore collection name for storing migration data.
    private let collectionName = "users"
    
    // MARK: - Public Methods
    
    /// Performs data migration.
    ///
    /// This method performs the following steps:
    /// 1. Collects data from local storage
    /// 2. Enables migration mode (connects to NewAppFB)
    /// 3. Writes data to Firestore
    /// 4. Disables migration mode
    ///
    /// - Parameters:
    ///   - userId: User identifier (email or external ID)
    ///   - completion: Callback with migration result
    func migrateData(userId: String, completion: @escaping (Result<Void, MigrationError>) -> Void) {
        print("Starting migration for user: \(userId)")
        
        // 1. Collect data from local storage
        guard let userData = collectLocalData() else {
            completion(.failure(.noDataToMigrate))
            return
        }
        
        // 2. Enable migration mode
        FirebaseConfigurationManager.shared.setMigrationMode(true)
        
        // Give time for Firebase initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performMigration(userId: userId, data: userData, completion: completion)
        }
    }
    
    // MARK: - Private Methods
    
    /// Collects data from local storage.
    ///
    /// In a real application this would collect data from:
    /// - UserDefaults
    /// - Keychain
    /// - CoreData / Realm
    /// - File system
    private func collectLocalData() -> [String: Any]? {
        let defaults = UserDefaults.standard
        
        // Check if there's data to migrate
        guard defaults.string(forKey: "userName") != nil ||
              defaults.string(forKey: "userEmail") != nil else {
            print("No local data found for migration")
            return nil
        }
        
        // Collect user profile
        var userData: [String: Any] = [:]
        
        if let name = defaults.string(forKey: "userName") {
            userData["name"] = name
        }
        
        if let email = defaults.string(forKey: "userEmail") {
            userData["email"] = email
        }
        
        if let role = defaults.string(forKey: "userRole") {
            userData["role"] = role
        }
        
        // Add creation timestamp
        let createdAt = defaults.double(forKey: "userCreatedAt")
        if createdAt > 0 {
            userData["createdAt"] = Timestamp(date: Date(timeIntervalSince1970: createdAt))
        }
        
        // Collect settings
        var settings: [String: Any] = [:]
        
        if let theme = defaults.string(forKey: "theme") {
            settings["theme"] = theme
        }
        
        if let language = defaults.string(forKey: "language") {
            settings["language"] = language
        }
        
        settings["notifications"] = defaults.bool(forKey: "notifications")
        
        if !settings.isEmpty {
            userData["settings"] = settings
        }
        
        // Add migration metadata
        userData["migratedAt"] = Timestamp()
        userData["migratedFrom"] = "OldApp"
        userData["migrationVersion"] = "1.0"
        
        print("Collected data fields: \(userData.keys.joined(separator: ", "))")
        
        return userData
    }
    
    /// Performs data write to Firestore.
    ///
    /// Uses Migration Firebase App to access NewAppFB project.
    private func performMigration(userId: String, data: [String: Any], completion: @escaping (Result<Void, MigrationError>) -> Void) {
        
        // Get Migration Firebase App
        guard let migrationApp = FirebaseApp.app(name: FBConfigurationType.migration.firebaseAppName) else {
            print("ERROR: Migration app not configured!")
            FirebaseConfigurationManager.shared.setMigrationMode(false)
            completion(.failure(.firebaseNotConfigured))
            return
        }
        
        // Create Firestore for Migration App
        let db = Firestore.firestore(app: migrationApp)
        
        // Path to document: users/{userId}
        let userDocRef = db.collection(collectionName).document(userId)
        
        print("Writing to: \(collectionName)/\(userId)")
        
        // Write data (merge: true for updating existing)
        userDocRef.setData(data, merge: true) { [weak self] error in
            // Disable migration mode
            FirebaseConfigurationManager.shared.setMigrationMode(false)
            
            if let error = error {
                print("Migration failed: \(error.localizedDescription)")
                completion(.failure(.firestoreError(error)))
            } else {
                print("Migration successful!")
                self?.markMigrationComplete()
                completion(.success(()))
            }
        }
    }
    
    /// Marks migration as complete.
    ///
    /// Saves flag in UserDefaults to avoid showing migration UI again.
    private func markMigrationComplete() {
        UserDefaults.standard.set(true, forKey: "migration_completed")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "migration_timestamp")
        print("Migration marked as complete")
    }
    
    /// Checks if migration was already performed.
    func isMigrationCompleted() -> Bool {
        return UserDefaults.standard.bool(forKey: "migration_completed")
    }
}
