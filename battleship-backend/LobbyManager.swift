import Foundation
import Vapor

class Lobby {
    var id: String
    var player1: (WebSocket?, Status) = (nil, .idle)
    var player2: (WebSocket?, Status) = (nil, .idle)
    var isFull -> Bool {
        if player1
    init(id: String){
        self.id = id
    }
}

class LobbyManager {
    static let shared = LobbyManager()
    private init(){}
}
