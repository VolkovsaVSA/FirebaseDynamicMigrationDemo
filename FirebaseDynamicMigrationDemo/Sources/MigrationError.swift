//
//  MigrationError.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  Data migration errors.
//

import Foundation

/// Errors that occur during data migration.
enum MigrationError: LocalizedError {
    /// Firebase is not configured.
    case firebaseNotConfigured
    
    /// No data to migrate.
    case noDataToMigrate
    
    /// Firestore error.
    case firestoreError(Error)
    
    /// User not found.
    case userNotFound
    
    /// Network error.
    case networkError(Error)
    
    /// Unknown error.
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not configured. Check configuration."
        case .noDataToMigrate:
            return "No data to migrate."
        case .firestoreError(let error):
            return "Firestore error: \(error.localizedDescription)"
        case .userNotFound:
            return "User not found."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknown(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
}
