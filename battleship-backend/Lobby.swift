import Foundation

class Player {
    enum Status {
        case matchmaking
        case idle
        case inMatch
    }
    let Username = ""
    var isInGame = false
    let userID: UUID
    init(p1ID: UUID = UUID()
}
    
