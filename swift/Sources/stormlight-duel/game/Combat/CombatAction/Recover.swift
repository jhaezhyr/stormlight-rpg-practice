public struct Recover: CombatAction {
    public init() {
    }

    public static let actionCost: Int = 1

    public func action(
        by characterRef: RpgCharacterRef, in gameSession: isolated GameSession = #isolation
    ) async {
        guard let character = gameSession.game.characters[characterRef] else {
            return
        }
        character.combatState!.recoveriesRemaining -= 1
        var amountToPut = character.recoveryDie.roll(rng: &gameSession.game.rng)
        await gameSession.game.broadcaster.tell(
            "You rolled your \(character.recoveryDie) and got a \(amountToPut)",
            to: characterRef
        )
        putLoop: while amountToPut > 0 {
            await gameSession.game.broadcaster.tell(
                "Your health is \(character.health.value)/\(character.health.maxValue), focus is \(character.focus.value)/\(character.focus.maxValue). You have \(amountToPut) left to restore with.",
                to: characterRef
            )
            var options = [HowToRecover]()
            let initialHealth = character.health.value
            let initialFocus = character.focus.value
            if character.health.value < character.health.maxValue {
                options.append(.recoverHealth)
            }
            if character.focus.value < character.focus.maxValue {
                options.append(.recoverFocus)
            }
            switch options.count {
            case 0:
                break putLoop
            case 1:
                switch options[0] {
                case .recoverFocus:
                    character.focus.restore(amountToPut)
                case .recoverHealth:
                    character.health.restore(amountToPut)
                }
            default:
                let decision = await character.brain.decide(
                    .howToRecover, options: options, in: gameSession.game.snapshot)
                switch decision {
                case .recoverFocus:
                    character.focus.restore(1)
                case .recoverHealth:
                    character.health.restore(1)
                }
                amountToPut -= 1
            }
            let finalHealth = character.health.value
            let finalFocus = character.focus.value
            await gameSession.game.broadcaster.tell(
                "You restored \(finalHealth - initialHealth) health and \(finalFocus - initialFocus) focus",
                to: characterRef
            )
        }
    }

    public func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        Self.canMaybeTakeAction(by: characterRef, in: gameSnapshot)
    }

    public static func canMaybeTakeAction(
        by character: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool {
        guard let character = gameSnapshot.characters[character] else {
            return false
        }
        guard let combatState = character.combatState else {
            return false
        }
        if combatState.actionsRemaining < actionCost {
            return false
        }
        if combatState.recoveriesRemaining < 1 {
            return false
        }
        return true
    }
}

public enum HowToRecover: Equatable, Sendable {
    case recoverHealth
    case recoverFocus
}
