//
//  MigrationViewModel.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  ViewModel for data migration screen.
//

import Foundation
import Combine

@MainActor
class MigrationViewModel: ObservableObject {
    
    // MARK: - User Data
    
    @Published var userName: String = ""
    @Published var userEmail: String = ""
    @Published var userRole: String = "user"
    
    // MARK: - Settings
    
    @Published var theme: String = "light"
    @Published var language: String = "ru"
    @Published var notifications: Bool = true
    
    // MARK: - Migration
    
    @Published var userId: String = ""
    @Published var isLoading: Bool = false
    @Published var statusMessage: String?
    @Published var isSuccess: Bool = false
    
    // MARK: - Actions
    
    func startMigration() {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        statusMessage = nil
        
        // Save data to UserDefaults (for demo purposes - collecting data)
        saveToUserDefaults()
        
        // Start migration
        DataMigrationManager.shared.migrateData(userId: userId) { [weak self] result in
            Task { @MainActor in
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.isSuccess = true
                    self?.statusMessage = "Data migrated successfully!"
                    
                case .failure(let error):
                    self?.isSuccess = false
                    self?.statusMessage = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func saveToUserDefaults() {
        UserDefaults.standard.set(userName, forKey: "userName")
        UserDefaults.standard.set(userEmail, forKey: "userEmail")
        UserDefaults.standard.set(userRole, forKey: "userRole")
        UserDefaults.standard.set(theme, forKey: "theme")
        UserDefaults.standard.set(language, forKey: "language")
        UserDefaults.standard.set(notifications, forKey: "notifications")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "userCreatedAt")
    }
}
