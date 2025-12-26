//
//  ImportViewModel.swift
//  FirebaseDynamicMigrationDemo
//
//  Created by Sergei Volkov on 26.12.2025.
//
//  ViewModel for data import screen.
//

import Foundation
import FirebaseFirestore

@MainActor
class ImportViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var userId: String = ""
    @Published var isLoading: Bool = false
    @Published var statusMessage: String?
    @Published var isSuccess: Bool = false
    @Published var importedData: [String: Any]?
    
    private let importer = DataImporter()
    
    // MARK: - Actions
    
    func importData() {
        guard !userId.isEmpty else { return }
        
        isLoading = true
        statusMessage = nil
        importedData = nil
        
        Task {
            do {
                if let data = try await importer.importUserData(userId: userId) {
                    isSuccess = true
                    statusMessage = "Data imported successfully!"
                    importedData = data
                } else {
                    isSuccess = false
                    statusMessage = "No data found for user: \(userId)"
                }
            } catch {
                isSuccess = false
                statusMessage = "Error: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
}
