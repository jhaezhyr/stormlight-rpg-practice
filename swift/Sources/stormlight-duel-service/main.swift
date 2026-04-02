import Hummingbird
import HummingbirdWebSocket
import stormlight_duel
import text_brain

// MARK: - Helper Functions

func handleConnection(_ connection: WebTextInterfaceConnection) async throws {
    await connection.display(
        "prompt",
        message: """
            Welcome to STORMLIGHT DUEL!

            1. New PvE duel (vs CPU)
            2. New PvP duel (host — receive an arena code)
            3. Join PvP duel (enter arena code)
            """, interface: nil)

    let choice = try await connection.getAnswer()

    switch choice {
    case "1":
        try await startPvEGame(connection)
    case "2":
        try await startPvPAsHost(connection)
    case "3":
        try await startPvPAsGuest(connection)
    default:
        await connection.display("hint", message: "Invalid choice", interface: nil)
    }
}

/// Creates a brain for a template based on whether it has a connection.
func makeBrain(
    for template: PlayerBuilderTemplate,
    ref: RpgCharacterRef
) async throws -> RpgCharacterBrain {
    if let connection = template.connection as? WebTextInterfaceConnection {
        return await TextBrain(
            characterRef: ref,
            ui: TextInterfaceProxy(connection: connection)
        )
    } else {
        switch template.cpuBrainKey {
        case .level1:
            return Mark1CpuBrain(for: ref)
        case .none, .level2:
            return Mark2CpuBrain(for: ref)
        }
    }
}

func startPvEGame(_ connection: WebTextInterfaceConnection) async throws {
    let builder = GameBuilderSession()
    let playerTemplate = try await builder.buildPlayerCharacter(connection: connection)
    let enemyTemplate = try await builder.buildEnemyCharacter(connection: connection)
    let session = try await GameSession.from(
        [playerTemplate, enemyTemplate], brainFactory: makeBrain)
    try await session.switch(to: Combat(map: Map.emptyDuel))
}

func startPvPAsHost(_ connection: WebTextInterfaceConnection) async throws {
    let builder = GameBuilderSession()
    let myTemplate = try await builder.buildPlayerCharacter(connection: connection)

    let arenaCode = generateArenaCode()
    await connection.display(
        "hint", message: "Your arena code: \(arenaCode)\nWaiting for opponent...", interface: nil)

    let (guestConnection, guestTemplate) = try await Lobby.shared.hostMatch(arenaCode: arenaCode)

    await connection.display("hint", message: "Opponent joined! Starting...", interface: nil)
    await guestConnection.display(
        "hint", message: "Opponent joined! Starting...", interface: nil)

    // Set up the templates with connections
    var hostTemplate = myTemplate
    hostTemplate.connection = connection as Any
    var guestTemplateWithConn = guestTemplate
    guestTemplateWithConn.connection = guestConnection as Any

    do {
        let session = try await GameSession.from(
            [hostTemplate, guestTemplateWithConn], brainFactory: makeBrain)
        try await session.switch(to: Combat(map: Map.emptyDuel))
        await guestConnection.signalGameEnd()
    } catch {
        await guestConnection.signalGameError(error)
        throw error
    }
}

func startPvPAsGuest(_ connection: WebTextInterfaceConnection) async throws {
    await connection.display("prompt", message: "Enter arena code:", interface: nil)
    let arenaCode = try await connection.getAnswer()
    let uppercodeCode = arenaCode.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)

    var myTemplate = try await GameBuilderSession().buildPlayerCharacter(connection: connection)
    myTemplate.connection = connection as Any

    try await Lobby.shared.joinMatch(
        arenaCode: uppercodeCode, guestConnection: connection, guestTemplate: myTemplate)

    await connection.display(
        "hint", message: "Joined! Waiting for host to start...", interface: nil)
    try await connection.waitForGameEnd()
}

// MARK: - Server Setup

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
            try await handleConnection(connection)
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
