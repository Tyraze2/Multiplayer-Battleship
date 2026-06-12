import Foundation
import Vapor

class Lobby {
    var id: String
    var player1: Player?
    var player2: Player?
    var isFull: Bool {
        return player1 != nil && player2 != nil 
    }
    init(id: String){
        self.id = id
    }
}

class LobbyManager {
    static let shared = LobbyManager()
    var lobbyList: [String: Lobby] = [:]
    private init(){}
    
    func addLobby(id: String) {
        let newLobby = Lobby(id: id)
        lobbyList[id] = newLobby
    }
    func AddPlayerToLobby {
        if player1 = nil {
            player1 = Player
        }
        if player2 = nil {
            player2 = Player
        }
    }
}
