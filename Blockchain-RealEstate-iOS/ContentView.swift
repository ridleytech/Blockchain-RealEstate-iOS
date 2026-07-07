//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var walletConnect = WalletConnectManager()
    private let headerColor = Color(red: 33.0 / 255.0, green: 37.0 / 255.0, blue: 41.0 / 255.0)

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text("Error loading properties")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            Task { await viewModel.load() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Wallet")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Spacer()
                                    if walletConnect.isConnecting {
                                        ProgressView()
                                    } else {
                                        Button("Connect") {
                                            Task { await walletConnect.connect() }
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }

                                if let uri = walletConnect.lastPairingURI {
                                    Text(uri)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }

                                if let error = walletConnect.lastError {
                                    Text(error)
                                        .font(.caption2)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        ForEach(viewModel.properties) { property in
                            NavigationLink {
                                PropertyDetailView(propertyId: property.id)
                            } label: {
                                PropertyRow(property: property)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                            .listRowSeparator(.hidden)
                        }
                    }
                    .tint(Color.accentColor)
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color(uiColor: .systemGroupedBackground))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Blockchain Real Estate")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .toolbarBackground(headerColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .tint(.white)
            .task {
                walletConnect.configure()
                await viewModel.load()
            }
        }
    }
}

private struct PropertyRow: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                PropertyImageView(url: property.primaryImageURL)
                    .frame(width: 88, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(property.title ?? "Untitled")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    Text(addressLine)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 2) {
                    Text(sharePriceText)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                    Text("per share")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("\(property.soldShares) / \(property.totalShares ?? 0) shares sold")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(totalPriceText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: property.soldProgress)
                    .tint(Color.accentColor)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.25), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var addressLine: String {
        let street = property.address?.street
        let city = property.address?.city
        if let street, !street.isEmpty, let city, !city.isEmpty {
            return "\(street), \(city)"
        }
        return street ?? city ?? ""
    }

    private var sharePriceText: String {
        if let sharePrice = property.sharePrice {
            return currencyFormatter.string(from: NSNumber(value: sharePrice)) ?? "-"
        }
        return "-"
    }

    private var totalPriceText: String {
        if let price = property.price {
            return currencyFormatter.string(from: NSNumber(value: price)) ?? ""
        }
        return ""
    }

    private var currencyFormatter: NumberFormatter {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f
    }
}

private struct PropertyImageView: View {
    let url: URL?

    var body: some View {
        ZStack {
            Color(uiColor: .tertiarySystemGroupedBackground)
            if let url {
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
    }
}

#Preview {
    ContentView()
//        .modelContainer(for: Item.self, inMemory: true)
}
