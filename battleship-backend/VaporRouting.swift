import Vapor

var playersOnline: [WebSocket] = []

func APIConnection(_ app: Application) throws {
    app.webSocket("ws"){
        req, ws in

        playersOnline.append(ws)
        ws.send("Connected")

        ws.onText {
            ws, text in
            guard let data = text.data(using: .utf8) else {return}
            do {
                let packet = try JSONDecoder().decode(GamePacket.self, from: data)
                
                if packet.action == "join" {
                    let lobbyUpdate = ["status": "lobby_updated"]
                    let encodedData = try JSONEncoder().encode(lobbyUpdate)
                    
                    if let jsonString = String(data: encodedData, encoding: .utf8) {
                        for connection in activeConnections {
                            connection.send(jsonString)
                        }
                    }
                }
            } 
            catch {
                print("Error")
            }
        }
    }
}
