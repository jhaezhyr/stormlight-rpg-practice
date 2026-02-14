public protocol TextInterfaceConnection: Sendable {
    func getAnswer() async throws -> String
    func display(_ type: String, message: String, interface: String?) async
}

public actor TextInterfaceProxy<Connection: TextInterfaceConnection> {
    let connection: Connection

    public init(connection: Connection) {
        self.connection = connection
    }
    public func event(_ message: String, interface: String?) async {
        await connection.display("event", message: message, interface: interface)
    }
    public func hint(_ message: String, interface: String?) async {
        await connection.display("hint", message: message, interface: interface)
    }
    public func prompt(_ message: String, interface: String?) async throws -> String {
        await connection.display("prompt", message: message, interface: interface)
        let answer = try await connection.getAnswer()
        return answer
    }
}
