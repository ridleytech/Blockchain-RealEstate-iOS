//
//  ContentView.swift
//  Blockchain-RealEstate-iOS
//
//  Created by Randall Ridley on 7/7/26.
//

import Foundation
import Starscream
import WalletConnectNetworking
import WalletConnectRelay

final class WalletConnectService {
    static let shared = WalletConnectService()

    private init() {}

    func configure() {
        Networking.configure(
            projectId: "9f1079622952d162dbc4a3a7ba9a0fed",
            socketFactory: StarscreamSocketFactory()
        )
    }
}

private struct StarscreamSocketFactory: WebSocketFactory {
    func create(with url: URL) -> WebSocketConnecting {
        var request = URLRequest(url: url)
        request.addValue("https://walletconnect.com", forHTTPHeaderField: "Origin")
        request.addValue("irn", forHTTPHeaderField: "Sec-WebSocket-Protocol")
        request.addValue("Blockchain-RealEstate-iOS", forHTTPHeaderField: "User-Agent")

        return StarscreamWebSocket(request: request)
    }
}

private final class StarscreamWebSocket: WebSocketConnecting {
    var request: URLRequest {
        didSet {
            socket.request = request
            if isConnected {
                socket.disconnect()
            }
            socket.connect()
        }
    }

    private(set) var isConnected: Bool = false

    var onConnect: (() -> Void)?
    var onDisconnect: ((Error?) -> Void)?
    var onText: ((String) -> Void)?

    private let socket: WebSocket

    init(request: URLRequest) {
        self.request = request

        let socket = WebSocket(request: request)
        socket.callbackQueue = DispatchQueue(label: "com.walletconnect.sdk.socket", attributes: .concurrent)
        self.socket = socket
        self.socket.delegate = self
        self.socket.connect()
    }

    func connect() {
        socket.connect()
    }

    func disconnect() {
        socket.disconnect()
    }

    func write(string: String, completion: (() -> Void)?) {
        socket.write(string: string, completion: completion)
    }
}

extension StarscreamWebSocket: WebSocketDelegate {
    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
        case .connected:
            isConnected = true
            onConnect?()
        case .disconnected:
            isConnected = false
            onDisconnect?(nil)
        case .text(let text):
            onText?(text)
        case .error(let error):
            isConnected = false
            onDisconnect?(error)
        case .cancelled:
            isConnected = false
            onDisconnect?(nil)
        default:
            break
        }
    }
}
