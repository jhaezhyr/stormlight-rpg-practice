public struct ReactiveStrikeProvider: SelfListenerHolderLeaf {
    public var selfListeners: [any SelfListenerProtocol]
    public init(
        for characterRef: RpgCharacterRef, in gameSession: isolated GameSession = #isolation
    ) {
        let action = {
            @Sendable
            (
                gameSession: isolated GameSession,
                character: AnyRpgCharacter,
                direction: Direction1D
            ) in
            guard character.primaryKey != characterRef else {
                return
            }
            guard let me = gameSession.game.anyCharacter(at: characterRef) else {
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
            let oldSpace = character.combatState!.space - (direction == .right ? 5 : -5)
            let wasTouching = myReach.touchesOrOverlaps(oldSpace)
            guard wasTouching && !myReach.touchesOrOverlaps(character.combatState!.space) else {
                return
            }
            let choice = await me.brain.decide(
                .reactiveStrikeChoice, options: ReactiveStrikeDecision.allCases,
                in: gameSession.game.snapshot)
            guard choice == .shouldStrikeReactively else {
                return
            }
            me.focus.value -= 1
            me.combatState!.reactionsRemaining -= 1
            await Strike(character.primaryKey, with: meleeWeaponToUse.primaryKey).action(
                by: characterRef, in: gameSession)
        }
        // TODO relies on the BUG that selfListen fires for every character, not just me
        self.selfListeners = [
            gameSession.selfListen(MoveHook.stepped(direction: .left, carefully: false)) {
                await action($0, $1, .left)
            },
            gameSession.selfListen(MoveHook.stepped(direction: .right, carefully: false)) {
                await action($0, $1, .right)
            },
        ]
    }
}

public enum ReactiveStrikeDecision: Sendable, Equatable, CaseIterable {
    case shouldStrikeReactively
    case shouldNotStrikeReactively
}
