public protocol Responder {
    var handlers: [any EventHandlerProtocol] { get }
    var childResponders: [any Responder] { get }
}
extension Responder {
    public func respondAndPassOn(to event: any Event, in gameSession: isolated GameSession) async {
        await respondIfListening(to: event, in: gameSession)
        for child in childResponders {
            await child.respondAndPassOn(to: event, in: gameSession)
        }
    }
    private func respondIfListening(to event: any Event, in gameSession: isolated GameSession) async
    {
        for handler in handlers {
            await handler.handleIfOfRightType(event, in: gameSession)
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
    func handle(_ event: Event, in gameSession: isolated GameSession) async
}
extension EventHandlerProtocol {
    func handleIfOfRightType(_ event: Any, in gameSession: isolated GameSession) async {
        if let event = event as? Event {
            await handle(event, in: gameSession)
        }
    }
}

public struct EventHandler<Event>: EventHandlerProtocol {
    private let handler: (_ event: Event, _ gameSession: isolated GameSession) async -> Void
    public init(
        handler: @escaping (_ event: Event, _ gameSession: isolated GameSession) async -> Void
    ) {
        self.handler = handler
    }

    public func handle(_ event: Event, in gameSession: isolated GameSession) async {
        await self.handler(event, gameSession)
    }
}
