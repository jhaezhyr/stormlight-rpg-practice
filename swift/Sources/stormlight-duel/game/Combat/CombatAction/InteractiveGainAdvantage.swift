public struct InteractiveGainAdvantage: CombatAction {
    public static var actionName: CombatActionName { GainAdvantage.actionName }
    public let opponent: RpgCharacterRef?
    public let chosenSkill: CoreSkillName?

    public init(
        opponent: RpgCharacterRef?,
        chosenSkill: CoreSkillName?,
    ) {
        self.opponent = opponent
        self.chosenSkill = chosenSkill
    }

    public static func canMaybeTakeAction(
        by character: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool {
        GainAdvantage.canMaybeTakeAction(by: character, in: gameSnapshot)
    }

    public func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession)
        async throws
    {
        guard let character = gameSession.game.anyCharacter(at: characterRef) else {
            return
        }
        // Decide on an opponent and a skill
        let opponent = try await { (gameSession: isolated GameSession) async throws in
            if let opponent = self.opponent {
                return opponent
            }
            let opponentOptions = GainAdvantage.opponentOptions(
                by: characterRef,
                in: gameSession.game.snapshot()
            )
            switch opponentOptions.count {
            case 0:
                fatalError("Not possible. How did we get here?")
            case 1:
                return opponentOptions[0]
            default:
                let decision = try await character.brain.decide(
                    .targetForGainAdvantage,
                    options: opponentOptions,
                    in: gameSession.game.snapshot()
                )
                return decision
            }
        }(gameSession)

        let skill = try await { (gameSession: isolated GameSession) async throws in
            if let chosenSkill = self.chosenSkill {
                return chosenSkill
            }
            let skillOptions = GainAdvantage.skillOptions(
                by: characterRef, against: opponent, in: gameSession.game.snapshot())
            switch skillOptions.count {
            case 0:
                fatalError("Not possible. How did we get here?")
            case 1:
                return skillOptions[0]
            default:
                let decision = try await character.brain.decide(
                    .skillForGainAdvantage,
                    options: skillOptions,
                    in: gameSession.game.snapshot()
                )
                return decision
            }
        }(gameSession)

        try await GainAdvantage(opponent: opponent, skill: skill).action(
            by: characterRef,
            in: gameSession
        )
    }
}
