//
//  DataImporter.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Data importer for NewApp.
//
//  This class is used in NewApp to read migrated data
//  from the NewAppFB Firebase project.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

/// Migrated data importer.
///
/// ## Usage in NewApp
///
/// NewApp is directly connected to NewAppFB, so importing data
/// is done by simply reading from Firestore:
///
/// ```swift
/// let importer = DataImporter()
/// let userData = try await importer.importUserData(userId: "user@example.com")
/// ```
///
/// ## Data Structure
///
/// Expected structure in Firestore:
/// ```
/// users/{userId}
///   - name: String
///   - email: String
///   - role: String
///   - createdAt: Timestamp
///   - migratedAt: Timestamp
///   - settings: Map
///       - theme: String
///       - language: String
///       - notifications: Bool
/// ```
final class DataImporter {
    
    // MARK: - Properties
    
    /// User data collection name.
    private let collectionName = "users"
    
    /// Firestore instance.
    ///
    /// In NewApp this uses the default Firebase App since the app
    /// is directly connected to NewAppFB.
    private var db: Firestore {
        // In real NewApp this would be just Firestore.firestore()
        // In demo we use Migration App for demonstration
        if let migrationApp = FirebaseApp.app(name: FBConfigurationType.migration.firebaseAppName) {
            return Firestore.firestore(app: migrationApp)
        }
        return Firestore.firestore()
    }
    
    // MARK: - Public Methods
    
    /// Imports user data from Firestore.
    ///
    /// - Parameter userId: User identifier (same as used during migration)
    /// - Returns: Dictionary with user data or nil if data not found
    func importUserData(userId: String) async throws -> [String: Any]? {
        print("Importing data for user: \(userId)")
        
        // Enable Migration Mode for access to NewAppFB
        FirebaseConfigurationManager.shared.setMigrationMode(true)
        
        // Give time for initialization
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        defer {
            // Disable Migration Mode after completion
            FirebaseConfigurationManager.shared.setMigrationMode(false)
        }
        
        let userDocRef = db.collection(collectionName).document(userId)
        
        do {
            let document = try await userDocRef.getDocument()
            
            guard document.exists, let data = document.data() else {
                print("No data found for user: \(userId)")
                return nil
            }
            
            print("Data imported successfully")
            print("Fields: \(data.keys.joined(separator: ", "))")
            
            return data
            
        } catch {
            print("Import failed: \(error.localizedDescription)")
            throw MigrationError.firestoreError(error)
        }
    }
    
    /// Checks for migration data existence for a user.
    ///
    /// Used to determine if migration UI should be shown.
    ///
    /// - Parameter userId: User identifier
    /// - Returns: true if migration data exists
    func hasMigrationData(userId: String) async throws -> Bool {
        print("Checking migration data for: \(userId)")
        
        FirebaseConfigurationManager.shared.setMigrationMode(true)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        defer {
            FirebaseConfigurationManager.shared.setMigrationMode(false)
        }
        
        let userDocRef = db.collection(collectionName).document(userId)
        
        do {
            let document = try await userDocRef.getDocument()
            let exists = document.exists
            
            print(exists ? "Migration data found" : "No migration data")
            
            return exists
            
        } catch {
            print("Check failed: \(error.localizedDescription)")
            throw MigrationError.firestoreError(error)
        }
    }
    
    /// Deletes migration data after successful import.
    ///
    /// It's recommended to delete migration data after it has been
    /// successfully imported into NewApp for security reasons.
    ///
    /// - Parameter userId: User identifier
    func deleteMigrationData(userId: String) async throws {
        print("Deleting migration data for: \(userId)")
        
        FirebaseConfigurationManager.shared.setMigrationMode(true)
        try await Task.sleep(nanoseconds: 500_000_000)
        
        defer {
            FirebaseConfigurationManager.shared.setMigrationMode(false)
        }
        
        let userDocRef = db.collection(collectionName).document(userId)
        
        do {
            try await userDocRef.delete()
            print("Migration data deleted")
        } catch {
            print("Delete failed: \(error.localizedDescription)")
            throw MigrationError.firestoreError(error)
        }
    }
}
