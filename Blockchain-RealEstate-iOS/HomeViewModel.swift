//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let api = PropertyAPI()

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            properties = try await api.fetchAllProperties()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
