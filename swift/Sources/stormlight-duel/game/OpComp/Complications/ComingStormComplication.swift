public struct ComingStormComplication: Complication {
    public func canRun(on test: any RpgTest, in gameSession: isolated GameSession) -> Bool {
        // Can run on any test
        return true
    }

    public func run(
        decider: any RpgCharacterBrain,
        on test: any RpgTest,
        in gameSession: isolated GameSession
    )
        async throws
    {
        await gameSession.game.broadcaster.tellAll(
            NoTargetMessage(
                "A terrible storm is approaching! Each character must spend 1 focus or be knocked prone by the high winds!"
            )
        )

        // Get all character references
        let characterRefs = gameSession.game.snapshot().characters.keys

        for characterRef in characterRefs {
            guard var character = gameSession.game.anyCharacter(at: characterRef) else {
                continue
            }

            // Present choice to the character
            let choice = try await character.brain.decide(
                .complicationChoice,
                options: ComingStormChoice.allCases,
                in: gameSession.game.snapshot()
            )

            switch choice {
            case .spendFocus:
                // Try to spend 1 focus
                if character.focus.value >= 1 {
                    character.focus.value -= 1
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1: "$1 braces against the wind and spends 1 focus!",
                            wU: "You brace against the wind and spend 1 focus!",
                            as1: characterRef
                        )
                    )
                } else {
                    // Can't spend focus, so become prone
                    let proneCondition = Prone(in: gameSession)
                    character.conditions.upsert(AnyCondition(proneCondition))
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1: "$1 has no focus to spend and is knocked prone!",
                            wU: "You have no focus to spend and are knocked prone!",
                            as1: characterRef
                        )
                    )
                }

            case .becomeProne:
                // Accept being knocked prone
                let proneCondition = Prone(in: gameSession)
                character.conditions.upsert(AnyCondition(proneCondition))
                await gameSession.game.broadcaster.tellAll(
                    SingleTargetMessage(
                        w1: "$1 is knocked prone by the high winds!",
                        wU: "You are knocked prone by the high winds!",
                        as1: characterRef
                    )
                )
            }

            // Update the character in the game
            gameSession.game.updateAnyCharacter(character)
        }
    }
}

public enum ComingStormChoice: String, Sendable, CaseIterable, CustomStringConvertible {
    case spendFocus = "Spend 1 focus"
    case becomeProne = "Accept being knocked prone"

    public var description: String {
        rawValue
    }
}
