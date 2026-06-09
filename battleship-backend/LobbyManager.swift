import Foundation
import Vapor

class Lobby {
    var id: String
    var player1: WebSocket? = nil
    var player2: WebSocket? = nil
    init(id: UUID){
        self.id = id
    }
}