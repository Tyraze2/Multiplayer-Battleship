import Foundation
import Vapor

class Lobby {
    var id: String
    var player1?
    var player2?
    var isFull: Bool {
        if player1 != nil && player2 != nil {
            return true
        } else {
            return false
        }
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
}
