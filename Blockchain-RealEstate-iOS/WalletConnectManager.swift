//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import Foundation
import SwiftUI

import WalletConnectPairing

@MainActor
final class WalletConnectManager: ObservableObject {
    @Published private(set) var isConnecting: Bool = false
    @Published private(set) var lastPairingURI: String?
    @Published private(set) var lastError: String?

    func configure(metadata: AppMetadata = .defaultDappMetadata) {
        Pair.configure(metadata: metadata)
    }

    func connect() async {
        isConnecting = true
        lastError = nil

        do {
            let uri = try await Pair.instance.create()
            lastPairingURI = uri.absoluteString
        } catch {
            lastError = String(describing: error)
        }

        isConnecting = false
    }
}

private extension AppMetadata {
    static var defaultDappMetadata: AppMetadata {
        AppMetadata(
            name: "Blockchain Real Estate",
            description: "Fractional real estate investing",
            url: "https://ridleytech.io",
            icons: ["https://walletconnect.com/walletconnect-logo.png"]
        )
    }
}
