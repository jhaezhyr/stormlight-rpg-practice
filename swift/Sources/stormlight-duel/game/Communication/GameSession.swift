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

    public static func playSinglePlayerGame<Brain: RpgCharacterBrain>(
        brainForPlayer: @Sendable (_ characterRef: RpgCharacterRef) async throws -> Brain
    ) async throws {
        let session = GameSession(
            game: Game(
                characters: [],
                broadcaster: Broadcaster(),
                gameMasterBrain: Level1CpuBrain(
                    for: RpgCharacterRef(name: "GM EN")
                )))
        func doIt(in session: isolated GameSession) async throws {
            let player1IsArcher = Bool.random(using: &session.game.rng)
            let player1Ref = RpgCharacterRef(
                name: "Kal (\(player1IsArcher ? "Archer" : "Spear Infantry"))")
            if player1IsArcher {
                PrefabCharacters.archer(
                    ref: player1Ref,
                    isPlayer: true,
                    brain: try await brainForPlayer(player1Ref),
                    andAddTo: session,
                )
            } else {
                PrefabCharacters.spearInfantry(
                    ref: player1Ref,
                    isPlayer: true,
                    brain: try await brainForPlayer(player1Ref),
                    andAddTo: session,
                )
            }
            let player2IsArcher = Bool.random(using: &session.game.rng)
            let player2Ref = RpgCharacterRef(
                name: "Shallan (\(player2IsArcher ? "Archer" : "Spear Infantry"))")
            if player2IsArcher {
                PrefabCharacters.archer(
                    ref: player2Ref,
                    isPlayer: false,
                    brain: Level1CpuBrain(
                        for: player2Ref
                    ),
                    andAddTo: session,
                )
            } else {
                PrefabCharacters.spearInfantry(
                    ref: player2Ref,
                    isPlayer: false,
                    brain: Level1CpuBrain(
                        for: player2Ref
                    ),
                    andAddTo: session,
                )
            }
            try await session.switch(to: Combat(map: Map.emptyDuel))
        }
        try await doIt(in: session)
    }

    public static func playTwoPlayerGame<Brain1: RpgCharacterBrain, Brain2: RpgCharacterBrain>(
        brainForPlayer1: @Sendable (_ characterRef: RpgCharacterRef) async throws -> Brain1,
        brainForPlayer2: @Sendable (_ characterRef: RpgCharacterRef) async throws -> Brain2
    ) async throws {
        let session = GameSession(
            game: Game(
                characters: [],
                broadcaster: Broadcaster(),
                gameMasterBrain: Level1CpuBrain(
                    for: RpgCharacterRef(name: "GM EN")
                )))
        func doIt(in session: isolated GameSession) async throws {
            let player1IsArcher = Bool.random(using: &session.game.rng)
            let player1Ref = RpgCharacterRef(
                name: "Player 1 (\(player1IsArcher ? "Archer" : "Spear Infantry"))")
            if player1IsArcher {
                PrefabCharacters.archer(
                    ref: player1Ref,
                    isPlayer: true,
                    brain: try await brainForPlayer1(player1Ref),
                    andAddTo: session,
                )
            } else {
                PrefabCharacters.spearInfantry(
                    ref: player1Ref,
                    isPlayer: true,
                    brain: try await brainForPlayer1(player1Ref),
                    andAddTo: session,
                )
            }
            let player2IsArcher = Bool.random(using: &session.game.rng)
            let player2Ref = RpgCharacterRef(
                name: "Player 2 (\(player2IsArcher ? "Archer" : "Spear Infantry"))")
            if player2IsArcher {
                PrefabCharacters.archer(
                    ref: player2Ref,
                    isPlayer: true,
                    brain: try await brainForPlayer2(player2Ref),
                    andAddTo: session,
                )
            } else {
                PrefabCharacters.spearInfantry(
                    ref: player2Ref,
                    isPlayer: true,
                    brain: try await brainForPlayer2(player2Ref),
                    andAddTo: session,
                )
            }
            try await session.switch(to: Combat(map: Map.emptyDuel))
        }
        try await doIt(in: session)
    }
}
