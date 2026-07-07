//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import Foundation

struct AICitation: Decodable, Identifiable {
    let id = UUID()
    let source: String?

    private enum CodingKeys: String, CodingKey {
        case source
    }
}

struct AIAskResponse: Decodable {
    let success: Bool?
    let answer: String?
    let citations: [AICitation]?
    let message: String?
}

@MainActor
final class PropertyAIChatViewModel: ObservableObject {
    @Published var question: String = ""
    @Published var answer: String = ""
    @Published var citations: [AICitation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    func ask(propertyId: String, token: String?) async {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        answer = ""
        citations = []

        do {
            var request = URLRequest(url: AppConfig.baseURL.appendingPathComponent("api/ai/ask"))
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let token, !token.isEmpty {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }

            let payload: [String: Any] = [
                "propertyId": propertyId,
                "question": trimmed
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let decoded = (try? JSONDecoder().decode(AIAskResponse.self, from: data))

            if !(200 ... 299).contains(http.statusCode) {
                let message = decoded?.message ?? String(data: data, encoding: .utf8)
                if http.statusCode == 401 {
                    errorMessage = message ?? "You need to be logged in to use chat."
                } else {
                    errorMessage = message ?? "Request failed (HTTP \(http.statusCode))"
                }
                isLoading = false
                return
            }

            guard decoded?.success == true else {
                errorMessage = decoded?.message ?? "Request failed"
                isLoading = false
                return
            }

            answer = decoded?.answer ?? ""
            citations = decoded?.citations ?? []
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}
