import Vapor
import Foundation

// MARK: - Status Enum
enum Status: String, Codable {
    case matchmaking
    case idle
    case inMatch
}

// MARK: - Player Class
class Player: Codable {
    let username: String
    var onlineStatus: Status = .idle
    let userID: UUID
    
    init(username: String?, userID: UUID = UUID()) {
        self.username = username ?? "Guest"
        self.userID = userID
    }
    
    enum CodingKeys: String, CodingKey {
        case username
        case onlineStatus
        case userID
    }
}

// MARK: - Lobby Class
class Lobby {
    var id: String
    var player1: Player?
    var player2: Player?
    var isFull: Bool {
        return player1 != nil && player2 != nil
    }
    
    init(id: String) {
        self.id = id
    }
}

// MARK: - Lobby Manager
class LobbyManager {
    static let shared = LobbyManager()
    var lobbyList: [String: Lobby] = [:]
    private let queue = DispatchQueue(label: "com.battleship.lobby", attributes: .concurrent)
    
    private init() {}
    
    func addLobby(id: String) {
        queue.async(flags: .barrier) {
            let newLobby = Lobby(id: id)
            self.lobbyList[id] = newLobby
            print("✅ Lobby \(id) created")
        }
    }
    
    func removeLobby(id: String) {
        queue.async(flags: .barrier) {
            self.lobbyList[id] = nil
            print("❌ Lobby \(id) removed")
        }
    }
    
    func addPlayerToLobby(lobbyID: String, player: Player) {
        queue.async(flags: .barrier) {
            guard let lobby = self.lobbyList[lobbyID] else {
                print("⚠️ Lobby \(lobbyID) not found")
                return
            }
            
            guard !lobby.isFull else {
                print("⚠️ Lobby \(lobbyID) is full")
                return
            }
            
            if lobby.player1 == nil {
                lobby.player1 = player
                print("✅ Player \(player.username) added to lobby \(lobbyID) as player1")
            } else if lobby.player2 == nil {
                lobby.player2 = player
                print("✅ Player \(player.username) added to lobby \(lobbyID) as player2")
            }
        }
    }
    
    func removePlayerFromLobby(lobbyID: String, userID: String) {
        queue.async(flags: .barrier) {
            guard let lobby = self.lobbyList[lobbyID] else {
                print("⚠️ Lobby \(lobbyID) not found")
                return
            }
            
            if lobby.player1?.userID.uuidString == userID {
                if let player = lobby.player1 {
                    print("❌ Player \(player.username) removed from lobby \(lobbyID)")
                }
                lobby.player1 = nil
            } else if lobby.player2?.userID.uuidString == userID {
                if let player = lobby.player2 {
                    print("❌ Player \(player.username) removed from lobby \(lobbyID)")
                }
                lobby.player2 = nil
            }
            
            // Remove empty lobbies
            if lobby.player1 == nil && lobby.player2 == nil {
                self.lobbyList[lobbyID] = nil
            }
        }
    }
    
    func getLobby(id: String) -> Lobby? {
        var result: Lobby?
        queue.sync {
            result = self.lobbyList[id]
        }
        return result
    }
    
    func getAllLobbies() -> [String: Lobby] {
        var result: [String: Lobby] = [:]
        queue.sync {
            result = self.lobbyList
        }
        return result
    }
}

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

// MARK: - AnyCodable for flexible JSON
enum AnyCodable: Codable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case double(Double)
    case array([AnyCodable])
    case dictionary([String: AnyCodable])
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
        } else if let value = try? container.decode([AnyCodable].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: AnyCodable].self) {
            self = .dictionary(value)
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
        case .array(let value):
            try container.encode(value)
        case .dictionary(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
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
    
    let lobbyUpdate = GameMessage(
        type: "lobby_update",
        content: [
            "status": AnyCodable("lobby_updated"),
            "playerCount": AnyCodable(WebSocketManager.shared.getPlayerCount()),
            "players": AnyCodable(players.map { player in
                AnyCodable.dictionary([
                    "playerId": AnyCodable(player.playerId),
                    "username": AnyCodable(player.username),
                    "onlineStatus": AnyCodable(player.onlineStatus)
                ])
            })
        ]
    )
    
    WebSocketManager.shared.broadcastMessage(lobbyUpdate)
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

// MARK: - Action Handlers
func handlePlayerJoin(packet: GamePacket, ws: WebSocket) {
    guard let username = packet.username else {
        sendError(ws, "Username required")
        return
    }
    
    let playerID = UUID(uuidString: packet.playerId) ?? UUID()
    let player = Player(username: username, userID: playerID)
    player.onlineStatus = .idle
    
    WebSocketManager.shared.addConnection(playerId: packet.playerId, player: player, socket: ws)
    
    // Send confirmation to joining player
    let joinConfirm = GameMessage(
        type: "join_confirmed",
        content: [
            "playerId": AnyCodable(packet.playerId),
            "username": AnyCodable(username),
            "userID": AnyCodable(playerID.uuidString)
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
        broadcastLobbyUpdate()
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

// MARK: - Main API Connection with WebSocket Routes
func APIConnection(_ app: Application) throws {
    // Configure CORS for WebSocket and HTTP connections
    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .contentType, .origin, .userAgent, .accessControlAllowOrigin],
        exposedHeaders: [],
        maxAge: 600,
        cacheExposedHeaders: false,
        allowCredentials: true
    )
    app.middleware.use(CORSMiddleware(configuration: corsConfiguration))
    
    // Health check endpoint
    app.get("health") { req in
        return ["status": "healthy"]
    }
    
    // Get lobby list endpoint
    app.get("lobbies") { req in
        let lobbies = LobbyManager.shared.getAllLobbies()
        let lobbyList = lobbies.map { id, lobby in
            [
                "id": id,
                "isFull": lobby.isFull,
                "player1": lobby.player1?.username ?? "empty",
                "player2": lobby.player2?.username ?? "empty"
            ]
        }
        return ["lobbies": lobbyList]
    }
    
    // Create lobby endpoint
    app.post("lobbies", "create") { req -> [String: String] in
        let lobbyID = UUID().uuidString
        LobbyManager.shared.addLobby(id: lobbyID)
        return ["lobbyId": lobbyID]
    }
    
    // WebSocket endpoint for game connection
    app.webSocket("ws") { req, ws in
        var currentPlayerId: String?
        
        print("🔌 New WebSocket connection attempt")
        
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
                    
                case "ping":
                    let pongMessage = GameMessage(
                        type: "pong",
                        content: ["timestamp": AnyCodable(Int(Date().timeIntervalSince1970))]
                    )
                    WebSocketManager.shared.sendMessageToPlayer(playerId: packet.playerId, message: pongMessage)
                    
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
    
    // WebSocket endpoint for lobby updates
    app.webSocket("ws", "lobby") { req, ws in
        print("🔌 Lobby WebSocket connection established")
        
        // Send initial lobby state
        broadcastLobbyUpdate()
        
        ws.onClose.whenComplete { _ in
            print("❌ Lobby WebSocket disconnected")
        }
        
        ws.onError { ws, error in
            print("❌ Lobby WebSocket Error: \(error.localizedDescription)")
        }
    }
}
