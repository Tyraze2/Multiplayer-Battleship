import Vapor

var playersOnline: [WebSocket] = []

func APIConnection(_ app: Application) throws {
    app.webSocket("ws"){
        req, ws in
        ws.send("Connected")
        ws.onText {
            ws, text in
            print("Recived \(text)")
        }
    }
}
