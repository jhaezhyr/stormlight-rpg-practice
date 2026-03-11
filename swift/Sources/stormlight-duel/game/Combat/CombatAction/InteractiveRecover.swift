public struct InteractiveRecover: CombatAction {
    public static var actionName: CombatActionName {
        "Recover"
    }
    public init() {
    }

    public static func actionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        1
    }

    public func action(
        by characterRef: RpgCharacterRef, in gameSession: isolated GameSession = #isolation
    ) async throws {
        guard let character = gameSession.game.characters[characterRef]?.core else {
            return
        }
        character.combatState!.recoveriesRemaining -= 1
        let amountToPut = character.recoveryDie.roll(rng: &gameSession.game.rng)
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                w1: "$1 rolled their \(character.recoveryDie) and got a \(amountToPut)",
                wU: "You rolled your \(character.recoveryDie) and got a \(amountToPut)",
                as1: characterRef)
        )
        let initialHealth = character.health.value
        let initialFocus = character.focus.value
        await gameSession.game.broadcaster.tellHint(
            "Your health is \(character.health.value)/\(character.health.maxValue), focus is \(character.focus.value)/\(character.focus.maxValue). You have \(amountToPut) left to restore with.",
            to: characterRef
        )
        let options = HowToRecover.options(
            total: amountToPut,
            healthToFull: character.health.maxValue - character.health.value,
            focusToFull: character.focus.maxValue - character.focus.value
        )
        let decision = try await character.brain.decide(
            .howToRecover,
            options: options,
            in: gameSession.game.snapshot()
        )
        guard decision.total <= amountToPut else {
            return
        }
        character.health.restore(decision.amountHealth)
        character.focus.restore(decision.amountFocus)

        let finalHealth = character.health.value
        let finalFocus = character.focus.value
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                w1:
                    "$1 restored \(finalHealth - initialHealth) health and \(finalFocus - initialFocus) focus",
                wU:
                    "You restored \(finalHealth - initialHealth) health and \(finalFocus - initialFocus) focus",
                as1: characterRef)
        )
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
        if combatState.recoveriesRemaining < 1 {
            return false
        }
        return true
    }
}

public struct HowToRecover: Equatable, Sendable {
    public var total: Int
    public var amountHealth: Int
    public var amountFocus: Int
    public var amountLeftover: Int

    public init?(
        total: Int,
        amountHealth: Int,
        amountFocus: Int,
        amountLeftover: Int,
    ) {
        if amountHealth + amountFocus + amountLeftover != total {
            return nil
        }
        self.total = total
        self.amountHealth = amountHealth
        self.amountFocus = amountFocus
        self.amountLeftover = amountLeftover
    }

    public static func options(total: Int, healthToFull: Int, focusToFull: Int) -> [Self] {
        (0...min(total, healthToFull)).reversed().map { healthToRestore in
            let focusToTryToRestore = total - healthToRestore
            let focusToRestore = min(focusToFull, focusToTryToRestore)
            let leftover = focusToTryToRestore - focusToRestore
            return Self(
                total: total,
                amountHealth: healthToRestore,
                amountFocus: focusToRestore,
                amountLeftover: leftover
            )!
        }
    }
}
