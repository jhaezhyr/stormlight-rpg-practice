public struct ComingStormComplication: Complication {
    public var name: String {
        "Coming Storm"
    }
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
                "A terrible storm is approaching! Each character must spend 1 focus or be knocked prone by the high winds."
            )
        )

        characterLoop: for character in gameSession.game.characters {
            if character.focus.value >= 1 {
                let choice = try await character.brain.decide(
                    .shouldStandStrongInComingStorm,
                    options: ComingStormChoice.allCases,
                    in: gameSession.game.snapshot()
                )

                if choice == .spendFocus {
                    character.focus.value -= 1
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1: "$1 stands strong against the wind.",
                            wU: "You stand strong against the wind.",
                            as1: character.primaryKey
                        )
                    )
                    continue characterLoop
                }
            }
            let proneCondition = Prone(in: gameSession)
            character.conditions.upsert(AnyCondition(proneCondition))
            await gameSession.game.broadcaster.tellAll(
                SingleTargetMessage(
                    w1: "$1 is knocked prone by the high winds.",
                    wU: "You are knocked prone by the high winds.",
                    as1: character.primaryKey
                )
            )
        }
    }
}

public enum ComingStormChoice: String, Sendable, CaseIterable, CustomStringConvertible {
    case spendFocus = "brace against the wind"
    case becomeProne = "accept being knocked prone"

    public var description: String {
        rawValue
    }
}
