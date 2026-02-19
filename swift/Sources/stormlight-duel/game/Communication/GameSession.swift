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
        let broadcaster = Broadcaster()

        let player1Ref = RpgCharacterRef(name: "Kal")
        let player1 = PlayerRpgCharacter(
            name: player1Ref.name,
            expertises: [],
            equipment: [
                await Readyable(basicWeapons[.crossbow]!(session), isReady: true),
                await Readyable(BasicArmorTypes.leather(in: session), isReady: true),
            ],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            reach: 0,
            conditions: [],
            brain: try await brainForPlayer(player1Ref),
            isPlayer: true
        )
        let player2 = PlayerRpgCharacter(
            name: "Shallan",
            expertises: [],
            equipment: [await Readyable(basicWeapons[.knife]!(session), isReady: true)],
            attributes: .init { _ in 2 },
            ranksInCoreSkills: .init { _ in 0 },
            ranksInOtherSkills: [:],
            health: .init(maxValue: 12),
            focus: .init(maxValue: 4),
            investiture: .init(maxValue: 0),
            reach: 0,
            conditions: [],
            brain: Level1CpuBrain(
                for: RpgCharacterRef(name: "Shallan")
            ),
            isPlayer: false
        )
        await session.provideGame(
            Game(
                characters: [player1, player2], broadcaster: broadcaster,
                gameMasterBrain: Level1CpuBrain(
                    for: RpgCharacterRef(name: "GM EN")
                )))

        try await session.switch(to: Combat(map: Map.emptyDuel))
    }
}
