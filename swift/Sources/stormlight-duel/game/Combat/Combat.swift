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

public enum TurnSpeed: Hashable, CaseIterable, Sendable {
    case fast, slow

    var actionsPerTurn: Int {
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
        // Let everyone start the combat.
        for ref in game.characters.keys {
            game.characters[ref]!.combatState = RpgCharacterCombatState(
                turnSpeed: .fast, reactionsRemaining: 1)
        }
        rounds: while true {
            // Give each character in this speed a turn
            for ref in game.characters.keys {
                let turnSpeed = await game.characters[ref]!.brain.decide(
                    options: TurnSpeed.allCases, in: game.snapshot)
                game.characters[ref]!.combatState!.turnSpeed = turnSpeed
            }
            speeds: for speed in TurnSpeed.allCases {
                // TODO allow characters to lower their speed mid-round somehow
                charactersThisTurn: for character in game.characters.filter({ c in
                    c.combatState!.turnSpeed == speed
                }) {
                    character.combatState!.reactionsRemaining = 1
                    character.combatState!.actionsRemaining =
                        character.combatState!.turnSpeed.actionsPerTurn
                    character.combatState!.weaponsUsed = []
                    await game.broadcaster.tellAll("\nIt's \(character.name)'s turn")
                    await game.naiveDispatch(
                        CombatPhase.startOfTurn, for: RpgCharacterRef(of: character),
                        in: gameSession)
                    actions: while true {
                        if isOver(in: game) {
                            break rounds
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

    public func isOver(in game: Game) -> Bool {
        !(game.characters.filter({ c in c.health.value > 0 }).count > 1)
    }
}
