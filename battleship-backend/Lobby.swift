import Foundation

enum Status {
        case matchmaking
        case idle
        case inMatch
}

class Player {
    let username: String
    var isInGame = false
    let userID: UUID
    init(username: String, userID: UUID = UUID())
}
    
