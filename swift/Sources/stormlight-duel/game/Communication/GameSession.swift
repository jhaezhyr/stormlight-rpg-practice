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
            let player2Ref = RpgCharacterRef(name: "Shallan Archer")
            let player2 = PrefabCharacters.archer(
                ref: player2Ref,
                isPlayer: false,
                brain: Level1CpuBrain(
                    for: player2Ref
                ),
                in: session,
            )
            session.game.characters.upsert(.init(player1))
            session.game.characters.upsert(.init(player2))
            try await session.switch(to: Combat(map: Map.emptyDuel))
        }
        try await doIt(in: session)
    }
}
