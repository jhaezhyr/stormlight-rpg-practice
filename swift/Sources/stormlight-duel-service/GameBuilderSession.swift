import stormlight_duel
import text_brain

actor GameBuilderSession {
    var players: [PlayerBuilderTemplate] = []

    func run(_ connection: WebTextInterfaceConnection) async throws -> (GameSession, any Scene) {
        let interface = TextInterfaceProxy(connection: connection)
        _ = try await interface.prompt(
            """
            Welcome to STORMLIGHT DUEL!

            This videogame experience is based on the "Cosmere Roleplaying Game" by
            Brotherwise Games, based on works by Brandon Sanderson. The videogame is
            written and hosted by Braeden Hintze.

                        * ** NEW GAME ** *

            Make your character and choose your opponenet.
            1: continue
            """, interface: "Welcome to STORMLIGHT DUEL!")
        try await chooseSinglePlayerGame(connection: connection)
        _ = try await interface.prompt(
            """
                            * ** INSTRUCTIONS ** *

            You play as a(n) \(players[0].prefab!) named \(players[0].name!). You are in a one-on-one
            combat with a(n) \(players[1].prefab!), \(players[1].name!). Bring them down.

            Anytime you are prompted to make a choice, you type in your answer and
            press ENTER. In some cases, you are given multiple numbered options. In
            other cases, your choices are a list of one-word commands. Some commands
            have single-letter aliases to make them easier to type.

            When the game waits for your input, you also can type "status" in order
            to see the map and the conditions of both characters. The map shows a(n) \(players[0].name!.first!)
            for your location, an \(players[1].name!.first!) for \(players[1].name!)'s location, and a . for every 5ft
            distance. The map is 1-dimensional to keep things simple and brutal.

            Do you understand?
            1: yes, life before death
            """, interface: "                * ** INSTRUCTIONS ** *")
        return try await (GameSession.from(players), Combat(map: Map.emptyDuel))
    }

    func chooseSinglePlayerGame(connection: WebTextInterfaceConnection) async throws {
        let interface = TextInterfaceProxy(connection: connection)
        self.players.append(PlayerBuilderTemplate(connection: connection))
        self.players.append(PlayerBuilderTemplate())
        self.players[0].prefab =
            switch Int(
                try await interface.prompt(
                    """
                    What will your character's class be?
                    :1 archer
                    :2 spear infantry
                    """,
                    interface: interfaceSoFar()
                ))
            {
            case 0: .archer
            case 1: .spearInfantry
            default: .spearInfantry
            }
        self.players[0].name =
            try await interface.prompt(
                """
                What will your character's name be?
                """,
                interface: interfaceSoFar()
            )
        self.players[0].isPlayer =
            switch Int(
                try await interface.prompt(
                    """
                    Will your character be a minion or a true player?
                    :1 player
                    :2 minion
                    """,
                    interface: interfaceSoFar()
                ))
            {
            case 0: true
            case 1: false
            default: false
            }
        self.players[1].prefab =
            switch Int(
                try await interface.prompt(
                    """
                    What will your opponent's class be?
                    :1 archer
                    :2 spear infantry
                    """,
                    interface: interfaceSoFar()
                ))
            {
            case 0: .archer
            case 1: .spearInfantry
            default: .spearInfantry
            }
        self.players[1].name =
            try await interface.prompt(
                """
                What will your opponent's name be?
                """,
                interface: interfaceSoFar()
            )
        self.players[1].isPlayer =
            switch Int(
                try await interface.prompt(
                    """
                    Will your opponent be a minion or a true player?
                    :1 player
                    :2 minion
                    """,
                    interface: interfaceSoFar()
                ))
            {
            case 0: true
            case 1: false
            default: false
            }
    }

    func interfaceSoFar() -> String {
        "\(players[0]) vs \(players[1])"
    }
}

struct PlayerBuilderTemplate: CustomStringConvertible, Sendable {
    var prefab: PlayerPrefabKey?
    var isPlayer: Bool?
    var name: String?
    var connection: WebTextInterfaceConnection?

    var description: String {
        "\(name ?? "unknown character")\(prefab.map { " the \($0)" } ?? "")\(isPlayer.map { $0 ? " (player)" : " (minion)"} ?? "")"
    }
}

enum PlayerPrefabKey: CustomStringConvertible {
    case archer
    case spearInfantry

    var description: String {
        switch self {
        case .archer: "archer"
        case .spearInfantry: "spear infantry"
        }
    }
}

extension GameSession {
    static func from(_ templates: [PlayerBuilderTemplate]) async throws -> GameSession {
        let session = GameSession(
            game: Game(
                characters: [], broadcaster: Broadcaster(),
                gameMasterBrain: Level1CpuBrain(for: .gameMaster)))
        func doIt(in gameSession: isolated GameSession) async throws {
            let brainForTemplate = {
                (template: PlayerBuilderTemplate) in
                if let connection = template.connection {
                    return
                        (try await TextBrain(
                            characterRef: .init(name: template.name!),
                            ui: TextInterfaceProxy(connection: connection)
                        ) as any RpgCharacterBrain)
                } else {
                    return (Level1CpuBrain(for: .init(name: template.name!)))
                }

            }
            for template in templates {
                switch template.prefab! {
                case .archer:
                    let brain = try await brainForTemplate(template)
                    PrefabCharacters.archer(
                        ref: .init(name: template.name!),
                        isPlayer: template.isPlayer!,
                        brain: brain,
                        andAddTo: gameSession)
                case .spearInfantry:
                    let brain = try await brainForTemplate(template)
                    PrefabCharacters.spearInfantry(
                        ref: .init(name: template.name!),
                        isPlayer: template.isPlayer!,
                        brain: brain,
                        andAddTo: gameSession)
                }
            }
        }
        try await doIt(in: session)
        return session
    }
}

enum UnderstandingChoice: String, Sendable, Hashable, CustomStringConvertible, CaseIterable {
    case yes = "yes, life before death"
    var description: String { self.rawValue }
}
