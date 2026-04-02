public actor GameSession {
    public let game: Game

    public init(game: Game) {
        self.game = game
    }

    private var _nextId = 0
    func nextId() -> Int {
        _nextId += 1
        return _nextId
    }

    /// Creates a GameSession from player builder templates.
    /// The brainFactory closure creates the appropriate brain for each template.
    public static func from(
        _ templates: [PlayerBuilderTemplate],
        brainFactory:
            @Sendable (_ template: PlayerBuilderTemplate, _ ref: RpgCharacterRef) async throws ->
            RpgCharacterBrain
    ) async throws -> GameSession {
        let session = GameSession(
            game: Game(
                characters: [],
                broadcaster: Broadcaster(),
                gameMasterBrain: RpgCharacterDummyBrain(
                    characterRef: RpgCharacterRef(name: "GM EN"),
                    defaultBehavior: .randomOption,
                )))

        func doIt(in session: isolated GameSession) async throws {
            for template in templates {
                let ref = RpgCharacterRef(name: template.name)
                let brain = try await brainFactory(template, ref)

                switch template.prefab {
                case .archer:
                    PrefabCharacters.archer(
                        ref: ref,
                        isPlayer: template.isPlayer,
                        brain: brain,
                        andAddTo: session
                    )
                case .spearInfantry:
                    PrefabCharacters.spearInfantry(
                        ref: ref,
                        isPlayer: template.isPlayer,
                        brain: brain,
                        andAddTo: session
                    )
                }
            }
            let answers = try await session.game.broadcaster.promptAll(
                .understanding,
                options: UnderstandingChoice.allCases,
                in: session
            )
            if !answers.allSatisfy({ (character, answer) in answer == .yes }) {
                await session.game.broadcaster.tellAll(
                    NoTargetMessage("The duel is off. A challenger has resigned."))
                throw CancellationError()
            }
            try await session.switch(to: Combat(map: Map.emptyDuel))
        }

        try await doIt(in: session)
        return session
    }
}

public enum UnderstandingChoice: String, Sendable, Hashable, CustomStringConvertible, CaseIterable {
    case yes = "yes, life before death"
    case no = "no, get me out of here"
    public var description: String { self.rawValue }
}
