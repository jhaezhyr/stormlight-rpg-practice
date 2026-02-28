extension Responder {
    public func respondAndPassOnSync(to event: any EventSync, in gameSession: isolated GameSession)
    {
        respondIfListeningSync(to: event, in: gameSession)
        for child in childResponders {
            child.respondAndPassOnSync(to: event, in: gameSession)
        }
    }
    private func respondIfListeningSync(
        to event: any EventSync, in gameSession: isolated GameSession
    ) {
        for handler in syncHandlers {
            handler.handleIfOfRightTypeSync(event, in: gameSession)
        }
    }
    private var allChildResponders: [any Responder] {
        childResponders + childResponders.flatMap { $0.allChildResponders }
    }
}
extension Responder {
    public var syncHandlers: [any EventHandlerSyncProtocol] { [] }
}

public protocol EventHandlerSyncProtocol {
    associatedtype Event
    func handle(_ event: Event, in gameSession: isolated GameSession)
}
extension EventHandlerSyncProtocol {
    func handleIfOfRightTypeSync(_ event: Any, in gameSession: isolated GameSession = #isolation) {
        if let event = event as? Event {
            handle(event, in: gameSession)
        }
    }
}

public protocol EventSync {}

public struct EventHandlerSync<E>: EventHandlerSyncProtocol {
    private let handler: (_ event: E, _ gameSession: isolated GameSession) -> Void
    public init(
        handler:
            @escaping (_ event: E, _ gameSession: isolated GameSession) -> Void
    ) {
        self.handler = handler
    }

    public func handle(_ event: E, in gameSession: isolated GameSession) {
        self.handler(event, gameSession)
    }
}
