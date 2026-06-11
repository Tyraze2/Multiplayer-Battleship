import Foundation
import Vapor

class Lobby {
    var id: String
    var player1: WebSocket? = nil
    var player2: WebSocket? = nil
    var isFull = true 
    init(id: String){
        self.id = id
    }
}

class LobbyManager {
    static let shared = LobbyManager()
    private init(){}
}
