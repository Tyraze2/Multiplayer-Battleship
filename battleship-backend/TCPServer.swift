import Foundation
import Network

// MARK: - TCP Server for Multiplayer Game
class GameTCPServer {
    private var listener: NWListener?
    private let port: NWEndpoint.Port
    private var connections: [NWConnection] = []
    private let connectionQueue = DispatchQueue(label: "com.battleship.tcp", attributes: .concurrent)
    
    init(port: UInt16 = 8080) {
        self.port = NWEndpoint.Port(rawValue: port) ?? 8080
    }
    
    /// Start the TCP server
    func start() {
        do {
            let parameters = NWParameters(tls: nil)
            parameters.allowLocalEndpointReuse = true
            parameters.includePeerToPeer = false
            
            listener = try NWListener(using: parameters, on: self.port)
            
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }
            
            listener?.stateUpdateHandler = { [weak self] state in
                switch state {
                case .ready:
                    print("✅ TCP Server started successfully on port \(self?.port.rawValue ?? 8080)")
                    self?.printLocalIPAddress()
                    
                case .failed(let error):
                    print("❌ TCP Server failed: \(error.localizedDescription)")
                    
                case .cancelled:
                    print("⚠️ TCP Server cancelled")
                    
                case .waiting(let error):
                    print("⏳ TCP Server waiting: \(error.localizedDescription)")
                    
                @unknown default:
                    print("⚠️ TCP Server state unknown")
                }
            }
            
            listener?.start(queue: .main)
            print("🔌 TCP Server initializing on port \(port.rawValue)...")
            
        } catch {
            print("❌ Failed to start TCP Server: \(error.localizedDescription)")
        }
    }
    
    /// Stop the TCP server
    func stop() {
        listener?.cancel()
        print("🛑 TCP Server stopped")
    }
    
    /// Handle new incoming connection
    private func handleNewConnection(_ connection: NWConnection) {
        print("🔗 New connection received from \(connection.endpoint)")
        
        connectionQueue.async(flags: .barrier) {
            self.connections.append(connection)
        }
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("✅ Connection established with \(connection.endpoint)")
                self?.receiveData(on: connection)
                
            case .failed(let error):
                print("❌ Connection failed: \(error.localizedDescription)")
                self?.removeConnection(connection)
                
            case .cancelled:
                print("⚠️ Connection cancelled")
                self?.removeConnection(connection)
                
            case .waiting(let error):
                print("⏳ Connection waiting: \(error.localizedDescription)")
                
            @unknown default:
                print("⚠️ Connection state unknown")
            }
        }
        
        connection.start(queue: .main)
    }
    
    /// Receive data from connection
    private func receiveData(on connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let error = error {
                print("❌ Receive error: \(error.localizedDescription)")
                self?.removeConnection(connection)
                return
            }
            
            if let data = data, !data.isEmpty {
                if let message = String(data: data, encoding: .utf8) {
                    print("📨 Received: \(message)")
                    // Echo response back to client
                    self?.sendData("Echo: \(message)", to: connection)
                }
            }
            
            if isComplete {
                print("⚠️ Connection closed by remote")
                self?.removeConnection(connection)
            } else {
                // Continue receiving
                self?.receiveData(on: connection)
            }
        }
    }
    
    /// Send data to a specific connection
    func sendData(_ message: String, to connection: NWConnection) {
        guard let data = (message + "\n").data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed { [weak self] error in
            if let error = error {
                print("❌ Send error: \(error.localizedDescription)")
                self?.removeConnection(connection)
            } else {
                print("📤 Sent: \(message)")
            }
        })
    }
    
    /// Broadcast data to all connected clients
    func broadcastData(_ message: String) {
        guard let data = (message + "\n").data(using: .utf8) else { return }
        
        var activeConnections: [NWConnection] = []
        connectionQueue.sync {
            activeConnections = self.connections
        }
        
        for connection in activeConnections {
            connection.send(content: data, completion: .contentProcessed { [weak self] error in
                if let error = error {
                    print("❌ Broadcast send error: \(error.localizedDescription)")
                    self?.removeConnection(connection)
                }
            })
        }
    }
    
    /// Remove connection from active list
    private func removeConnection(_ connection: NWConnection) {
        connectionQueue.async(flags: .barrier) {
            self.connections.removeAll { $0 === connection }
            print("🔌 Connection removed. Active connections: \(self.connections.count)")
        }
        connection.cancel()
    }
    
    /// Get active connection count
    func getConnectionCount() -> Int {
        var count = 0
        connectionQueue.sync {
            count = self.connections.count
        }
        return count
    }
    
    // MARK: - IP Address Helper
    
    /// Find and print the Mac's local IPv4 Wi-Fi IP address
    func printLocalIPAddress() {
        if let ipAddress = getLocalIPAddress() {
            print("🌐 Local Wi-Fi IPv4 Address: \(ipAddress)")
            print("📱 Frontend can connect to: tcp://\(ipAddress):\(port.rawValue)")
        } else {
            print("⚠️ Could not determine local IPv4 address")
        }
    }
    
    /// Get the local IPv4 address for Wi-Fi interface
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            
            let addressFamily = interface.ifa_addr.pointee.sa_family
            
            // Check for IPv4 addresses
            if addressFamily == AF_INET {
                // Get the interface name
                if let name = interface.ifa_name {
                    let interfaceName = String(cString: name)
                    
                    // Look for Wi-Fi or en0 interface
                    if interfaceName == "en0" || interfaceName.contains("en") {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        
                        if getnameinfo(
                            interface.ifa_addr,
                            socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname,
                            socklen_t(hostname.count),
                            nil,
                            0,
                            NI_NUMERICHOST
                        ) == 0 {
                            address = String(cString: hostname)
                            // Return first valid non-loopback address
                            if address != "127.0.0.1" {
                                return address
                            }
                        }
                    }
                }
            }
        }
        
        return address
    }
}

// MARK: - Helper: Import required headers for getifaddrs
import Darwin
