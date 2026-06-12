import Foundation
import Vapor

class Lobby {
    var id: String
    var player1: Player?
    var player2: Player?
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
    func AddPlayerToLobby() {
        guard {
            if Lobby.player1 != nil && Lobby.player2 != nil {
                return
            }
        }
        if Lobby.player1 == nil {
            Lobby.player1 = Player
        }
        if Lobby.player2 == nil {
            Lobby.player2 = Player
        }
    }
}
