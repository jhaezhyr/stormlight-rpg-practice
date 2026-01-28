public struct Damage: Equatable, Hashable, Sendable {
    public var amount: Int
    public var type: DamageType

    public init(_ amount: Int, type: DamageType) {
        self.amount = amount
        self.type = type
    }
}

public enum CombatPhase: HookTriggerForSomeRpgCharacter, Sendable {
    case startOfTurn
    case endOfTurn
}

public enum CombatTurnInitiativeChoice: Sendable {
    case goNow
    case waitForOthers
    case waitForSlowPhase
}

public struct CombatTurnInitiative: CaseIterable, Sendable, Hashable, CustomStringConvertible {
    public var isPlayer: Bool
    public var turnSpeed: TurnSpeed

    public var description: String {
        "\(turnSpeed == .fast ? "Fast" : "Slow") \(isPlayer ? "player" : "NPC") phase"
    }

    public static let playerFast: Self = .init(isPlayer: true, turnSpeed: .fast)
    public static let npcFast: Self = .init(isPlayer: false, turnSpeed: .fast)
    public static let playerSlow: Self = .init(isPlayer: true, turnSpeed: .slow)
    public static let npcSlow: Self = .init(isPlayer: false, turnSpeed: .slow)
    public static let allCases: [CombatTurnInitiative] = [
        .playerFast, .npcFast, .playerSlow, .npcSlow,
    ]
}

public enum TurnSpeed: Hashable, CaseIterable, Sendable {
    case fast, slow

    public var actionsPerTurn: Int {
        switch self {
        case .fast: 2
        case .slow: 3
        }
    }
}

public struct RpgCharacterCombatState: Sendable {
    public var turnSpeed: TurnSpeed
    public var actionsRemaining: Int = 0
    public var weaponsUsed: Set<WeaponName> = []
    public var actionsTaken: Set<CombatActionName> = []
    public var reactionsRemaining: Int = 0
    public var hasStrikeAdvantageOver: Set<RpgCharacterRef> = []
}

public struct Combat: Scene {
    public init() {
    }

    public func run(in gameSession: isolated GameSession = #isolation) async {
        let game = gameSession.game
        let players = game.characters.filter { $0.isPlayer }.map { $0.core }
        let nonPlayers = game.characters.filter { !$0.isPlayer }.map { $0.core }
        // Let everyone start the combat.
        for ref in game.characters.keys {
            game.characters[ref]!.combatState = RpgCharacterCombatState(
                turnSpeed: .fast, reactionsRemaining: 1
            )
        }
        rounds: for roundNum in 1... {
            await game.broadcaster.tellAll("======= ROUND \(roundNum) ========")
            var charactersPerPhase: CompleteDictionary<CombatTurnInitiative, [any RpgCharacter]> = [
                .playerFast: players,
                .npcFast: nonPlayers,
                .playerSlow: [],
                .npcSlow: [],
            ]
            for initiativePhase in CombatTurnInitiative.allCases {
                if !charactersPerPhase[initiativePhase].isEmpty {
                    await game.broadcaster.tellAll("--- \(initiativePhase) ---")
                } else {
                    await game.broadcaster.tellAll("Skipping \(initiativePhase)")
                }
                while !charactersPerPhase[initiativePhase].isEmpty {
                    for character in charactersPerPhase[initiativePhase] {
                        var options: [CombatTurnInitiativeChoice] = [.goNow]
                        if initiativePhase.turnSpeed == .fast {
                            options.append(.waitForSlowPhase)
                        }
                        if !charactersPerPhase[initiativePhase].filter({ $0 !== character }).isEmpty
                        {
                            options.append(.waitForOthers)
                        }
                        let initiativeChoice = await character.brain.decide(
                            options: options,
                            in: game.snapshot
                        )
                        switch initiativeChoice {
                        case .goNow:
                            if await self.doCharacterTurn(character) {
                                break rounds
                            }
                            charactersPerPhase[initiativePhase].removeAll(where: {
                                $0 === character
                            })

                        case .waitForOthers:
                            break
                        case .waitForSlowPhase:
                            charactersPerPhase[initiativePhase].removeAll(where: {
                                $0 === character
                            })
                            charactersPerPhase[
                                .init(isPlayer: initiativePhase.isPlayer, turnSpeed: .slow)
                            ].append(character)
                        }
                        // TODO Test it!
                    }
                }
            }
        }

        let winners = game.characters.filter { $0.health.value > 0 }
        if winners.count == 0 {
            await game.broadcaster.tellAll("You're all unconcious. Good job.")
        } else if winners.count == 1 {
            await game.broadcaster.tellAll(
                "\(winners.map { $0.core.name }.joined(separator: " and ")) won!")
        }
    }

    /// Returns whether the game is over.
    public func doCharacterTurn(
        _ character: any RpgCharacter, in gameSession: isolated GameSession = #isolation
    ) async -> Bool {
        let game = gameSession.game
        character.combatState!.reactionsRemaining = 1
        character.combatState!.actionsRemaining =
            character.combatState!.turnSpeed.actionsPerTurn
        await game.broadcaster.tellAll("\nIt's \(character.name)'s turn")
        await game.naiveDispatch(
            CombatPhase.startOfTurn, for: RpgCharacterRef(of: character),
            in: gameSession)
        actions: while true {
            if isOver(in: game) {
                return true
            }

            for someCharacter in game.characters {
                await game.broadcaster.tell(
                    "\(someCharacter.primaryKey == character.primaryKey ? "Your" : "\(someCharacter.name)'s") stats:\n"
                        + "  Health: \(someCharacter.health.value)/\(character.health.maxValue)\n"
                        + "  Focus: \(someCharacter.focus.value)/\(character.focus.maxValue)\n"
                        + "  Conditions: \(someCharacter.conditions.map { "\($0.core)" }.joined(separator: ","))",
                    to: character.primaryKey)
            }

            let choice = await character.brain.decide(
                type: CombatChoice.self, in: game.snapshot)
            guard case .action(let action) = choice else {
                break actions
            }
            if character.combatState!.actionsRemaining >= action.actionCost
                && character.focus.value >= action.focusCost
                && action.canTakeAction(by: character.primaryKey, in: game.snapshot)
                && !character.combatState!.actionsTaken.contains(action.actionName)
            {
                character.focus.value -= action.focusCost
                character.combatState!.actionsRemaining -= action.actionCost
                await action.action(by: character.primaryKey, in: gameSession)
            }
        }
        await game.naiveDispatch(
            CombatPhase.endOfTurn, for: character.primaryKey, in: gameSession)
        character.combatState!.weaponsUsed = []
        return false
    }

    public func isOver(in game: Game) -> Bool {
        !(game.characters.filter({ c in c.health.value > 0 }).count > 1)
    }
}
