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
    func AddPlayerToLobby(lobbyID: String, player: Player) {
        guard let lobby = lobbyList[lobbyID]
        else {
            return
        }
        guard lobby.player1 == nil || lobby.player2 == nil 
        else {
            return
        }
        if lobby.player1 == nil {
            lobby.player1 = player
        }
        if lobby.player2 == nil {
            lobby.player2 = player
        }
    }
    func RemovePlayerFromLobby(lobbyID: String, player: Player){
        guard lobby.player1 != nil || lobby.player2 != nil
        else {
            return
        }
        if lobby.player1 != nil {
            lobby.player1 = nil
        }
        if lobby.player2 != nil {
            lobby.player2 = nil
        }
}
