import Hummingbird
import HummingbirdWebSocket
import stormlight_duel
import text_brain

let router = Router()
router.get("status") { request, _ -> String in
    return "healthy"
}

let wsRouter = Router(context: BasicWebSocketRequestContext.self)
wsRouter.ws("/ws") { request, context in
    // allow upgrade
    .upgrade([:])
} onUpgrade: { inbound, outbound, context in
    try await withThrowingTaskGroup(of: Void.self) { group in
        let connection = WebTextInterfaceConnection(outbound: outbound)
        group.addTask {
            for try await message in inbound.messages(maxSize: 1024 * 1024) {
                await connection.storeAnswer(from: message)
            }
        }
        group.addTask {
            try await GameSession.playSinglePlayerGame {
                playerRef in
                return try await TextBrain(
                    characterRef: playerRef,
                    ui: TextInterfaceProxy(
                        connection: connection
                    )
                )
            }
        }
        try await group.next()
        // once one task has finished, cancel the other
        group.cancelAll()
    }
}

let app = Application(
    router: router,
    server: .http1WebSocketUpgrade(webSocketRouter: wsRouter),
    configuration: .init(address: .hostname("127.0.0.1", port: 10101))
)
try await app.runService()
