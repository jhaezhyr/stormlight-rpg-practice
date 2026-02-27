import CompleteDictionary

public struct Damage: Equatable, Hashable, Sendable {
    public var amount: Int
    public var type: DamageType

    public init(_ amount: Int, type: DamageType) {
        self.amount = amount
        self.type = type
    }
}

public enum CombatPhase: Sendable {
    case startOfTurn
    case endOfTurn
}
public struct CombatPhaseEvent: Event {
    public let phase: CombatPhase
    public let character: any RpgCharacter

    public init(phase: CombatPhase, character: any RpgCharacter) {
        self.phase = phase
        self.character = character
    }
}

public enum CombatTurnInitiativeChoice: Sendable, Equatable {
    case goNow
    case waitForOthers
    case waitForSlowPhase
}
extension CombatTurnInitiativeChoice: CustomStringConvertible {
    public var description: String {
        switch self {
        case .goNow: "go now"
        case .waitForOthers: "wait for others"
        case .waitForSlowPhase: "wait for slow phase"
        }
    }
}

public struct CombatTurnInitiative: CaseIterable, Sendable, Hashable, CustomStringConvertible {
    public var isPlayer: Bool
    public var turnSpeed: TurnSpeed

    public var description: String {
        "\(turnSpeed == .fast ? "fast" : "slow") \(isPlayer ? "player" : "NPC") phase"
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

public struct Combat: Scene {
    public let map: Map

    public init(map: Map) {
        self.map = map
    }

    public func start(in gameSession: isolated GameSession = #isolation) async throws {
        let game = gameSession.game
        // Let everyone start the combat.
        for (position, character) in zip(map.characterStartPositions, game.characters) {
            character.combatState = RpgCharacterCombatState(
                space: Space1D(
                    origin: position,
                    size: 5,
                    orientation: .left),
                for: character.primaryKey
            )
        }
        try await game.dispatch(SceneStartEvent())
    }

    public func run(in gameSession: isolated GameSession = #isolation) async throws {
        let game = gameSession.game
        let players = game.characters.filter { $0.isPlayer }.map { $0.core }
        let nonPlayers = game.characters.filter { !$0.isPlayer }.map { $0.core }
        try await start()
        rounds: for roundNum in 1... {
            await game.broadcaster.tellAll(NoTargetMessage("======= ROUND \(roundNum) ========"))
            var charactersPerPhase: CompleteDictionary<CombatTurnInitiative, [any RpgCharacter]> = [
                .playerFast: players,
                .npcFast: nonPlayers,
                .playerSlow: [],
                .npcSlow: [],
            ]
            for initiativePhase in CombatTurnInitiative.allCases {
                if !charactersPerPhase[initiativePhase].isEmpty {
                    await game.broadcaster.tellAll(NoTargetMessage("--- \(initiativePhase) ---"))
                } else {
                    await game.broadcaster.tellAll(NoTargetMessage("Skipping \(initiativePhase)"))
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
                        let initiativeChoice = try await character.brain.decide(
                            .initiative,
                            options: options,
                            in: game.snapshot()
                        )
                        switch initiativeChoice {
                        case .goNow:
                            if try await self.doCharacterTurn(character) {
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
                            character.combatState!.turnSpeed = .slow
                        }
                    }
                }
            }
        }

        let winners = game.characters.filter { $0.health.value > 0 }
        if winners.count == 0 {
            await game.broadcaster.tellAll(NoTargetMessage("You're all unconcious. Good job."))
        } else if winners.count == 1 {
            await game.broadcaster.tellAll(
                ContextFreeMultiTargetMessage(
                    "\(winners.enumerated().map { i, _ in "$\(i)" }.joined(separator: " and ")) won!",
                    for: winners.map { $0.primaryKey }))
        }
    }

    /// Returns whether the game is over.
    public func doCharacterTurn(
        _ character: any RpgCharacter, in gameSession: isolated GameSession = #isolation
    ) async throws -> Bool {
        let game = gameSession.game
        character.combatState!.reactionsRemaining = 1
        character.combatState!.actionsRemaining =
            character.combatState!.turnSpeed.actionsPerTurn
        await game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "It's $1's turn.", wU: "It's your turn.", as1: character.primaryKey))
        try await game.dispatch(CombatPhaseEvent(phase: .startOfTurn, character: character))
        actions: while true {
            if isOver(in: game) {
                return true
            }

            let choice = try await character.brain.decide(
                .combatChoice,
                nonIterableType: CombatChoice.self, in: game.snapshot())
            guard case .action(let action) = choice else {
                break actions
            }
            if action.canReallyTakeAction(by: character.primaryKey, in: game.snapshot()) {
                try await action.reallyTakeAction(by: character.primaryKey, in: gameSession)
            }
        }
        await game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "$1 ended their turn.", wU: "You ended your turn.", as1: character.primaryKey))
        try await game.dispatch(CombatPhaseEvent(phase: .endOfTurn, character: character))
        character.combatState!.turnsTaken += 1
        character.combatState!.weaponsUsed = []
        character.combatState!.actionsTaken = []
        return false
    }

    public func isOver(in game: Game) -> Bool {
        !(game.characters.filter({ c in c.health.value > 0 }).count > 1)
    }
}
