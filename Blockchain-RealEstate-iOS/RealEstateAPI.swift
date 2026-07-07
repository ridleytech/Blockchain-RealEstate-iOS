//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import Foundation

enum AppConfig {
    static let baseURL = URL(string: "http://localhost:4000")!
//    static let baseURL = URL(string: "https://5eda-2600-100d-b02e-7778-c108-dcd0-290c-dd35.ngrok-free.app")!

}

enum APIError: Error, LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(String?)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Request failed (HTTP \(code))"
        case .decodingError(let preview):
            if let preview, !preview.isEmpty {
                return "Failed to decode server response. Body preview: \(preview)"
            }
            return "Failed to decode server response"
        }
    }
}

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool?
    let count: Int?
    let data: T?
}

struct PropertyAddress: Decodable {
    let street: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let country: String?
}

struct PropertyImage: Decodable {
    let url: String?
    let isMain: Bool?

    init(url: String?, isMain: Bool?) {
        self.url = url
        self.isMain = isMain
    }

    init(from decoder: Decoder) throws {
        if let container = try? decoder.singleValueContainer(), let value = try? container.decode(String.self) {
            url = value
            isMain = nil
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        isMain = try container.decodeIfPresent(Bool.self, forKey: .isMain)
    }

    private enum CodingKeys: String, CodingKey {
        case url
        case isMain
    }
}

struct PropertyFeature: Decodable {
    let name: String?
    let value: String?
    let icon: String?
}

struct Property: Decodable, Identifiable {
    let id: String
    let title: String?
    let description: String?
    let address: PropertyAddress?
    let price: Double?
    let sharePrice: Double?
    let totalShares: Int?
    let availableShares: Int?
    let images: [PropertyImage]?
    let propertyType: String?
    let bedrooms: Int?
    let bathrooms: Int?
    let yearBuilt: Int?
    let size: Double?
    let squareFeet: Double?
    let features: [PropertyFeature]?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case title
        case description
        case address
        case price
        case sharePrice
        case totalShares
        case availableShares
        case images
        case propertyType
        case bedrooms
        case bathrooms
        case yearBuilt
        case size
        case squareFeet
        case features
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        address = try container.decodeIfPresent(PropertyAddress.self, forKey: .address)
        images = try container.decodeIfPresent([PropertyImage].self, forKey: .images)
        features = try container.decodeIfPresent([PropertyFeature].self, forKey: .features)

        propertyType = try container.decodeIfPresent(String.self, forKey: .propertyType)

        price = container.decodeLossyDoubleIfPresent(forKey: .price)
        sharePrice = container.decodeLossyDoubleIfPresent(forKey: .sharePrice)

        totalShares = container.decodeLossyIntIfPresent(forKey: .totalShares)
        availableShares = container.decodeLossyIntIfPresent(forKey: .availableShares)

        bedrooms = container.decodeLossyIntIfPresent(forKey: .bedrooms)
        bathrooms = container.decodeLossyIntIfPresent(forKey: .bathrooms)
        yearBuilt = container.decodeLossyIntIfPresent(forKey: .yearBuilt)

        size = container.decodeLossyDoubleIfPresent(forKey: .size)
        squareFeet = container.decodeLossyDoubleIfPresent(forKey: .squareFeet)
    }

    var soldShares: Int {
        max(0, (totalShares ?? 0) - (availableShares ?? 0))
    }

    var soldProgress: Double {
        let total = Double(max(totalShares ?? 0, 1))
        return Double(soldShares) / total
    }

    var primaryImageURL: URL? {
        let urlString = (images?.first(where: { $0.isMain == true })?.url) ?? images?.first?.url
        guard let urlString, !urlString.isEmpty else { return nil }

        if urlString.lowercased().hasPrefix("http://") || urlString.lowercased().hasPrefix("https://") {
            return URL(string: urlString)
        }

        let trimmed = urlString.hasPrefix("/") ? String(urlString.dropFirst()) : urlString
        return URL(string: "/images/\(trimmed)", relativeTo: AppConfig.baseURL)
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyIntIfPresent(forKey key: Key) -> Int? {
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return intValue
        }
        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return Int(doubleValue)
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            if let intParsed = Int(stringValue) {
                return intParsed
            }
            if let doubleParsed = Double(stringValue) {
                return Int(doubleParsed)
            }
        }
        return nil
    }

    func decodeLossyDoubleIfPresent(forKey key: Key) -> Double? {
        if let doubleValue = try? decodeIfPresent(Double.self, forKey: key) {
            return doubleValue
        }
        if let intValue = try? decodeIfPresent(Int.self, forKey: key) {
            return Double(intValue)
        }
        if let stringValue = try? decodeIfPresent(String.self, forKey: key) {
            return Double(stringValue)
        }
        return nil
    }
}

actor PropertyAPI {
    func fetchAllProperties() async throws -> [Property] {
        let url = AppConfig.baseURL.appendingPathComponent("api/properties")
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }

        do {
            if let envelope = try? JSONDecoder().decode(APIEnvelope<[Property]>.self, from: data),
               let properties = envelope.data
            {
                return properties
            }

            return try JSONDecoder().decode([Property].self, from: data)
        } catch {
            let preview = String(data: data.prefix(400), encoding: .utf8)
            throw APIError.decodingError(preview)
        }
    }

    func fetchProperty(id: String) async throws -> Property {
        let url = AppConfig.baseURL
            .appendingPathComponent("api/properties")
            .appendingPathComponent(id)

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(http.statusCode)
        }

        do {
            if let envelope = try? JSONDecoder().decode(APIEnvelope<Property>.self, from: data),
               let property = envelope.data
            {
                return property
            }

            return try JSONDecoder().decode(Property.self, from: data)
        } catch {
            let preview = String(data: data.prefix(400), encoding: .utf8)
            throw APIError.decodingError(preview)
        }
    }
}
