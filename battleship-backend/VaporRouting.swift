import Vapor
import Foundation

// MARK: - Message Structures
struct GamePacket: Codable {
    let action: String
    let playerId: String
    let username: String?
    let data: [String: AnyCodable]?
}

struct LobbyUpdate: Codable {
    let status: String
    let playerCount: Int
    let players: [LobbyPlayer]
}

struct LobbyPlayer: Codable {
    let playerId: String
    let username: String
    let onlineStatus: String
}

struct GameMessage: Codable {
    let type: String
    let content: [String: AnyCodable]
}

struct ErrorResponse: Codable {
    let error: String
    let timestamp: String
}

// MARK: - WebSocket Connection Manager
class WebSocketManager {
    static let shared = WebSocketManager()
    
    private var activePlayers: [String: WebSocketConnection] = [:]
    private let queue = DispatchQueue(label: "com.battleship.websocket", attributes: .concurrent)
    
    struct WebSocketConnection {
        let socket: WebSocket
        let player: Player
        let connectedAt: Date
    }
    
    func addConnection(playerId: String, player: Player, socket: WebSocket) {
        queue.async(flags: .barrier) {
            self.activePlayers[playerId] = WebSocketConnection(
                socket: socket,
                player: player,
                connectedAt: Date()
            )
            print("✅ Player \(player.username) (\(playerId)) connected")
        }
    }
    
    func removeConnection(playerId: String) {
        queue.async(flags: .barrier) {
            if let connection = self.activePlayers.removeValue(forKey: playerId) {
                print("❌ Player \(connection.player.username) (\(playerId)) disconnected")
            }
        }
    }
    
    func getConnection(playerId: String) -> WebSocketConnection? {
        var result: WebSocketConnection?
        queue.sync {
            result = self.activePlayers[playerId]
        }
        return result
    }
    
    func getAllConnections() -> [String: WebSocketConnection] {
        var result: [String: WebSocketConnection] = [:]
        queue.sync {
            result = self.activePlayers
        }
        return result
    }
    
    func getPlayerCount() -> Int {
        var count = 0
        queue.sync {
            count = self.activePlayers.count
        }
        return count
    }
    
    func broadcastMessage(_ message: GameMessage) {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to encode broadcast message")
            return
        }
        
        let connections = getAllConnections()
        connections.forEach { _, connection in
            connection.socket.send(jsonString)
        }
    }
    
    func sendMessageToPlayer(playerId: String, message: GameMessage) {
        let encoder = JSONEncoder()
        guard let jsonData = try? encoder.encode(message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to encode message for player \(playerId)")
            return
        }
        
        if let connection = getConnection(playerId: playerId) {
            connection.socket.send(jsonString)
        } else {
            print("⚠️ Player \(playerId) not found")
        }
    }
}

// MARK: - Main API Connection
func APIConnection(_ app: Application) throws {
    app.webSocket("ws") { req, ws in
        var currentPlayerId: String?
        
        // Handle incoming messages
        ws.onText { ws, text in
            guard let data = text.data(using: .utf8) else {
                sendError(ws, "Invalid message format")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let packet = try decoder.decode(GamePacket.self, from: data)
                
                currentPlayerId = packet.playerId
                
                // Handle different action types
                switch packet.action {
                case "join":
                    handlePlayerJoin(packet: packet, ws: ws)
                    
                case "ready":
                    handlePlayerReady(playerId: packet.playerId)
                    
                case "attack":
                    if let data = packet.data {
                        handleAttack(playerId: packet.playerId, data: data)
                    }
                    
                case "chat":
                    if let data = packet.data {
                        handleChat(playerId: packet.playerId, data: data)
                    }
                    
                default:
                    print("⚠️ Unknown action: \(packet.action)")
                }
                
            } catch let decodingError {
                print("❌ JSON Decoding Error: \(decodingError.localizedDescription)")
                sendError(ws, "Failed to decode packet: \(decodingError.localizedDescription)")
            }
        }
        
        // Handle disconnections
        ws.onClose.whenComplete { _ in
            if let playerId = currentPlayerId {
                WebSocketManager.shared.removeConnection(playerId: playerId)
                broadcastLobbyUpdate()
            }
        }
        
        // Handle errors
        ws.onError { ws, error in
            print("❌ WebSocket Error: \(error.localizedDescription)")
            if let playerId = currentPlayerId {
                WebSocketManager.shared.removeConnection(playerId: playerId)
            }
        }
        
        // Send initial connection message
        let welcomeMessage = GameMessage(
            type: "connected",
            content: ["message": AnyCodable("Welcome to Battleship")]
        )
        if let jsonData = try? JSONEncoder().encode(welcomeMessage),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            ws.send(jsonString)
        }
    }
}

// MARK: - Action Handlers
func handlePlayerJoin(packet: GamePacket, ws: WebSocket) {
    guard let username = packet.username else {
        sendError(ws, "Username required")
        return
    }
    
    let player = Player(username: username, userID: UUID(uuidString: packet.playerId) ?? UUID())
    player.onlineStatus = .idle
    
    WebSocketManager.shared.addConnection(playerId: packet.playerId, player: player, socket: ws)
    
    // Send confirmation to joining player
    let joinConfirm = GameMessage(
        type: "join_confirmed",
        content: [
            "playerId": AnyCodable(packet.playerId),
            "username": AnyCodable(username)
        ]
    )
    WebSocketManager.shared.sendMessageToPlayer(playerId: packet.playerId, message: joinConfirm)
    
    // Broadcast updated lobby to all players
    broadcastLobbyUpdate()
}

func handlePlayerReady(playerId: String) {
    if let connection = WebSocketManager.shared.getConnection(playerId: playerId) {
        connection.player.onlineStatus = .matchmaking
        print("🎮 Player \(connection.player.username) is ready")
        
        let readyMessage = GameMessage(
            type: "player_ready",
            content: ["playerId": AnyCodable(playerId)]
        )
        WebSocketManager.shared.broadcastMessage(readyMessage)
    }
}

func handleAttack(playerId: String, data: [String: AnyCodable]) {
    print("⚔️ Player \(playerId) attacking")
    
    let attackMessage = GameMessage(
        type: "attack",
        content: [
            "playerId": AnyCodable(playerId),
            "coordinates": data["coordinates"] ?? AnyCodable("unknown")
        ]
    )
    WebSocketManager.shared.broadcastMessage(attackMessage)
}

func handleChat(playerId: String, data: [String: AnyCodable]) {
    if let messageContent = data["message"] {
        if let connection = WebSocketManager.shared.getConnection(playerId: playerId) {
            let chatMessage = GameMessage(
                type: "chat",
                content: [
                    "username": AnyCodable(connection.player.username),
                    "message": messageContent
                ]
            )
            WebSocketManager.shared.broadcastMessage(chatMessage)
        }
    }
}

// MARK: - Utility Functions
func broadcastLobbyUpdate() {
    let connections = WebSocketManager.shared.getAllConnections()
    let players = connections.map { _, connection in
        LobbyPlayer(
            playerId: connection.player.userID.uuidString,
            username: connection.player.username,
            onlineStatus: connection.player.onlineStatus.rawValue
        )
    }
    
    let lobbyUpdate = LobbyUpdate(
        status: "lobby_updated",
        playerCount: WebSocketManager.shared.getPlayerCount(),
        players: players
    )
    
    let encoder = JSONEncoder()
    if let jsonData = try? encoder.encode(lobbyUpdate),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        let message = GameMessage(
            type: "lobby_update",
            content: [:]
        )
        WebSocketManager.shared.broadcastMessage(message)
    }
}

func sendError(_ ws: WebSocket, _ errorMessage: String) {
    let error = ErrorResponse(
        error: errorMessage,
        timestamp: ISO8601DateFormatter().string(from: Date())
    )
    
    if let jsonData = try? JSONEncoder().encode(error),
       let jsonString = String(data: jsonData, encoding: .utf8) {
        ws.send(jsonString)
    }
}

// MARK: - AnyCodable for flexible JSON
enum AnyCodable: Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode AnyCodable")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .double(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
