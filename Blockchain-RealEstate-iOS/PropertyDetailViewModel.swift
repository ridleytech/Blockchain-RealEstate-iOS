//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import Foundation

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published var property: Property? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let api = PropertyAPI()

    func load(id: String) async {
        isLoading = true
        errorMessage = nil

        do {
            property = try await api.fetchProperty(id: id)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
