//typealias EventHandler1<Event> = (_ event: Event, _ gameSession: isolated GameSession) -> Void

protocol Responder {
    associatedtype ChildResponders: Collection where ChildResponders.Element == any Responder
    var childResponders: ChildResponders { get }
    associatedtype AllChildResponders: Collection where AllChildResponders.Element == any Responder
    var allChildResponders: AllChildResponders { get }
    associatedtype EventHandlers: Collection where EventHandlers.Element == any EventHandlerProtocol
    var handlers: EventHandlers { get }

    func respondIfListening(to event: Any, in gameSession: isolated GameSession)
}
extension Responder {
    func respondIfListening(to event: Any, in gameSession: isolated GameSession) {
        for handler in handlers {
            handler.handleIfOfRightType(event, in: gameSession)
        }
    }
}

protocol EventHandlerProtocol {
    associatedtype Event
    func handle(_ event: Event, in gameSession: isolated GameSession)
}
extension EventHandlerProtocol {
    func handleIfOfRightType(_ event: Any, in gameSession: isolated GameSession) {
        if let event = event as? Event {
            handle(event, in: gameSession)
        }
    }
}

struct EventHandler<Event>: EventHandlerProtocol {
    func handle(_ event: Event, in gameSession: isolated GameSession) {

    }
}
