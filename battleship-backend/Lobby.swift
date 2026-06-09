import Foundation

enum Status {
        case matchmaking
        case idle
        case inMatch
}

class Player {
    let username: String
    var onlineStatus: Status = .idle
    let userID: UUID
    init(username: String, userID: UUID = UUID())
}
    
