import Foundation

enum Status: String, Codable  {
        case matchmaking
        case idle
        case inMatch
}

class Player: Codable {
    let username: String
    var onlineStatus: Status = .idle
    let userID: UUID
    init(username: String, userID: UUID = UUID())
}
    
