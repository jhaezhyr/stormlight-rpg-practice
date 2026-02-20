public actor GameSession {
    private var _game: Game?
    public var game: Game { _game! }

    public init(game: Game? = nil) {
        if let game {
            self._game = game
        }
    }

    public func provideGame(_ game: Game) {
        self._game = game
    }

    private var _nextId = 0
    func nextId() -> Int {
        _nextId += 1
        return _nextId
    }

    public static func playSinglePlayerGame<Brain: RpgCharacterBrain>(
        brainForPlayer: @Sendable (_ characterRef: RpgCharacterRef) async throws -> Brain
    ) async throws {

        let session = GameSession()
        func doIt(in session: isolated GameSession) async throws {
            let broadcaster = Broadcaster()
            session.provideGame(
                Game(
                    characters: [],
                    broadcaster: broadcaster,
                    gameMasterBrain: Level1CpuBrain(
                        for: RpgCharacterRef(name: "GM EN")
                    )))

            let player1Ref = RpgCharacterRef(name: "Archer Kal")
            let player1 = PrefabCharacters.archer(
                ref: player1Ref,
                isPlayer: true,
                brain: try await brainForPlayer(player1Ref),
                in: session,
            )
            let player2 = PlayerRpgCharacter(
                name: "Shallan",
                expertises: [],
                equipment: [Readyable(basicWeapons[.knife]!(session), isReady: true)],
                attributes: .init { _ in 2 },
                ranksInCoreSkills: .init { _ in 0 },
                ranksInOtherSkills: [:],
                health: .init(maxValue: 12),
                focus: .init(maxValue: 4),
                investiture: .init(maxValue: 0),
                reach: 0,
                features: [],
                conditions: [],
                brain: Level1CpuBrain(
                    for: RpgCharacterRef(name: "Shallan")
                ),
                isPlayer: false
            )
            session.game.characters.upsert(.init(player1))
            session.game.characters.upsert(.init(player2))
            try await session.switch(to: Combat(map: Map.emptyDuel))
        }
        try await doIt(in: session)
    }
}
