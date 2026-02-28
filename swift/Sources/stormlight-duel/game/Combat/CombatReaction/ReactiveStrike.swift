public struct ReactiveStrikeProvider: Responder {
    public var handlers: [any EventHandlerProtocol]
    public init(
        for meRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.handlers = [
            EventHandler<MovementStepEvent> {
                (event, gameSession) in
                let other = event.subject
                let direction = event.direction
                guard !event.carefully else {
                    return
                }
                // Check if the moving character has Outmaneuver condition
                guard !other.conditions.contains(where: { $0.type == OutmaneuverCondition.type })
                else {
                    return
                }
                // TODO When teams exist, this will have to check for actual
                guard other.primaryKey != meRef else {
                    return
                }
                guard let me = gameSession.game.anyCharacter(at: meRef) else {
                    return
                }
                guard me.focus.value >= 1 else {
                    return
                }
                guard me.combatState!.reactionsRemaining >= 1 else {
                    return
                }
                guard let readyableMeleeWeaponToUse = me.equipment.filter({ $0.isReady }).first,
                    let meleeWeaponToUse = readyableMeleeWeaponToUse.core.core as? any Weapon,
                    case WeaponRange.melee(let extraReach) = meleeWeaponToUse.range
                else {
                    return
                }
                let myReach = me.combatState!.space.expanded(by: extraReach ?? 0)
                let oldSpace = other.combatState!.space - (direction == .right ? 5 : -5)
                let wasTouching = myReach.touchesOrOverlaps(oldSpace)
                guard wasTouching && !myReach.touchesOrOverlaps(other.combatState!.space) else {
                    return
                }
                let choice = try await me.brain.decide(
                    .reactiveStrikeChoice, options: ReactiveStrikeDecision.allCases,
                    in: gameSession.game.snapshot())
                guard choice == .shouldStrikeReactively else {
                    return
                }
                me.focus.value -= 1
                me.combatState!.reactionsRemaining -= 1
                try await Strike(other.primaryKey, with: meleeWeaponToUse.primaryKey).action(
                    by: meRef)
            }
        ]
    }
}

public enum ReactiveStrikeDecision: Sendable, Equatable, CaseIterable {
    case shouldStrikeReactively
    case shouldNotStrikeReactively
}
