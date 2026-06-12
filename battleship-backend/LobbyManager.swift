import Foundation
import Vapor

class Lobby {
    var id: String
    var player1 = Player()
    var player2 = Player()
    var isFull -> Bool {
        if player1 != nil && player2 != nil {
            return true
        }
    }
    init(id: String){
        self.id = id
    }
}

class LobbyManager {
    static let shared = LobbyManager()
    var lobbyList: [String, Lobby] = [:]
    private init(){}
    func addLobby{
        
    }
}
