public protocol Responder {
    var handlers: [any EventHandlerProtocol] { get }
    var syncHandlers: [any EventHandlerSyncProtocol] { get }
    var childResponders: [any Responder] { get }
}
extension Responder {
    public func respondAndPassOn(to event: any Event, in gameSession: isolated GameSession)
        async throws
    {
        try await respondIfListening(to: event, in: gameSession)
        for child in childResponders {
            try await child.respondAndPassOn(to: event, in: gameSession)
        }
    }
    private func respondIfListening(to event: any Event, in gameSession: isolated GameSession)
        async throws
    {
        for handler in handlers {
            try await handler.handleIfOfRightType(event, in: gameSession)
        }
    }
    private var allChildResponders: [any Responder] {
        childResponders + childResponders.flatMap { $0.allChildResponders }
    }
}
extension Responder {
    public var handlers: [any EventHandlerProtocol] { [] }
    public var childResponders: [any Responder] { [] }
}

public protocol Event {}

public protocol EventHandlerProtocol {
    associatedtype Event
    func handle(_ event: Event, in gameSession: isolated GameSession) async throws
}
extension EventHandlerProtocol {
    func handleIfOfRightType(_ event: Any, in gameSession: isolated GameSession) async throws {
        if let event = event as? Event {
            try await handle(event, in: gameSession)
        }
    }
}

public struct EventHandler<Event>: EventHandlerProtocol {
    private let handler: (_ event: Event, _ gameSession: isolated GameSession) async throws -> Void
    public init(
        handler:
            @escaping (_ event: Event, _ gameSession: isolated GameSession) async throws -> Void
    ) {
        self.handler = handler
    }

    public func handle(_ event: Event, in gameSession: isolated GameSession) async throws {
        try await self.handler(event, gameSession)
    }
}
