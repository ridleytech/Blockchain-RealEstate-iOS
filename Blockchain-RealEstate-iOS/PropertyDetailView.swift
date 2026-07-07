//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import SwiftUI

struct PropertyDetailView: View {
    let propertyId: String

    @StateObject private var viewModel = PropertyDetailViewModel()
    private let headerColor = Color(red: 33.0 / 255.0, green: 37.0 / 255.0, blue: 41.0 / 255.0)

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 12) {
                    Text("Error loading property")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Retry") {
                        Task { await viewModel.load(id: propertyId) }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let property = viewModel.property {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        PropertyHero(property: property)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(property.title ?? "Untitled")
                                .font(.title).bold()

                            Text(fullAddress(property))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)

                        PricingCard(property: property)
                            .padding(.horizontal, 16)

                        DetailsCard(property: property)
                            .padding(.horizontal, 16)

                        if let features = property.features, !features.isEmpty {
                            FeaturesCard(features: features)
                                .padding(.horizontal, 16)
                        }

                        PropertyAIChatView(propertyId: property.id)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 12)
                }
                .background(Color(uiColor: .systemGroupedBackground))
            } else {
                Text("Property not found")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(headerColor, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .tint(.white)
        .task {
            await viewModel.load(id: propertyId)
        }
    }

    private func fullAddress(_ property: Property) -> String {
        guard let address = property.address else { return "Address not available" }
        let parts: [String] = [
            address.street,
            address.city,
            address.state,
            address.zipCode
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.isEmpty ? "Address not available" : parts.joined(separator: ", ")
    }
}

private struct PropertyHero: View {
    let property: Property

    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemGroupedBackground)
            if let url = property.primaryImageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "house")
                            .foregroundStyle(.secondary)
                    @unknown default:
                        Image(systemName: "house")
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Image(systemName: "house")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }
}

private struct PricingCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(priceText)
                    .font(.title2).bold()
                    .foregroundStyle(.primary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(sharePriceText)
                        .font(.headline)
                        .foregroundStyle(.tint)
                    Text("per share")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Text("Available Shares")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(property.availableShares ?? 0)")
            }
            .font(.subheadline)

            HStack {
                Text("Total Shares")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(property.totalShares ?? 0)")
            }
            .font(.subheadline)

            ProgressView(value: property.soldProgress)
                .tint(Color.accentColor)

            Text("\(property.soldShares) / \(property.totalShares ?? 0) shares sold")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }

    private var priceText: String {
        if let price = property.price {
            return currencyFormatter.string(from: NSNumber(value: price)) ?? "$0"
        }
        return "$0"
    }

    private var sharePriceText: String {
        if let sharePrice = property.sharePrice {
            return currencyFormatter.string(from: NSNumber(value: sharePrice)) ?? "-"
        }
        return "-"
    }
}

private struct DetailsCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Property Details")
                .font(.headline)

            HStack {
                DetailPill(title: "Beds", value: intText(property.bedrooms))
                DetailPill(title: "Baths", value: intText(property.bathrooms))
                DetailPill(title: "Year", value: intText(property.yearBuilt))
            }

            if let type = property.propertyType, !type.isEmpty {
                HStack {
                    Text("Type")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(type)
                }
                .font(.subheadline)
            }

            let areaValue = property.squareFeet ?? property.size
            if let areaValue {
                HStack {
                    Text("Area")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(areaValue)) sqft")
                }
                .font(.subheadline)
            }

            Divider()

            Text("Description")
                .font(.headline)

            Text(property.description ?? "No description available.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func intText(_ value: Int?) -> String {
        guard let value else { return "-" }
        return String(value)
    }
}

private struct DetailPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct FeaturesCard: View {
    let features: [PropertyFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Features")
                .font(.headline)

            ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                HStack(alignment: .firstTextBaseline) {
                    Text("•")
                        .foregroundStyle(.secondary)
                    Text(feature.name ?? "")
                        .font(.subheadline)
                    Spacer()
                    Text(feature.value ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
