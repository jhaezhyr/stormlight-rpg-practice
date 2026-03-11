public struct ReactiveStrikeProvider: Responder {
    public var handlers: [any EventHandlerProtocol]
    public init(
        for meRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.handlers = [
            EventHandler<MovementStepEvent> {
                (event, gameSession) in
                guard let me = gameSession.game.anyCharacter(at: meRef) else {
                    return
                }
                guard
                    let reaction = try await {
                        let reaction = ReactiveStrike(
                            stepWasCareful: event.carefully,
                            stepDirection: event.direction,
                            stepper: event.subject.primaryKey
                        )
                        guard reaction.canTakeAction(by: meRef, in: gameSession.game.snapshot())
                        else {
                            return Optional<ReactiveStrike>.none
                        }
                        let calculation = ReactionCalculation(
                            hook: .couldReact,
                            for: meRef,
                            reaction: reaction
                        )
                        try await gameSession.game.dispatch(
                            calculation)
                        return calculation.reaction
                    }()
                else {
                    return
                }
                guard reaction.canReallyTakeAction(by: meRef, in: gameSession.game.snapshot())
                else {
                    return
                }
                let choice = try await me.brain.decide(
                    .reactiveStrikeChoice,
                    options: ReactiveStrikeDecision.allCases,
                    in: gameSession.game.snapshot()
                )
                if choice == .shouldStrikeReactively {
                    try await reaction.reallyTakeAction(by: meRef)
                }
            }
        ]
    }
}

public struct ReactiveStrike: CombatReaction {
    public static var canBeTakenMoreThanOncePerTurn: Bool { true }
    public static func focusCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        1
    }
    public static func reactionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        1
    }
    public var editableFocusCost = 1
    public func focusCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot) -> Int {
        self.editableFocusCost
    }
    public var editableReactionCost = 1
    public func reactionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot) -> Int
    {
        self.editableReactionCost
    }

    public var stepWasCareful: Bool
    public var stepDirection: Direction1D
    public var stepper: RpgCharacterRef

    public func canTakeAction(by meRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        guard !stepWasCareful else {
            return false
        }
        guard
            let coward = gameSnapshot.characters[stepper],
            let me = gameSnapshot.characters[meRef]
        else {
            return false
        }
        // Check if the moving character has Outmaneuver condition
        guard !coward.conditions.contains(where: { $0.type == OutmaneuverCondition.type })
        else {
            return false
        }
        guard stepper != meRef else {
            return false
        }
        guard let (_, extraReach) = meleeWeapon(for: me) else {
            return false
        }
        let myReach = me.combatState!.space.expanded(by: extraReach ?? 0)
        let oldSpace = coward.combatState!.space - (stepDirection == .right ? 5 : -5)
        let wasTouching = myReach.touchesOrOverlaps(oldSpace)
        guard wasTouching && !myReach.touchesOrOverlaps(coward.combatState!.space) else {
            return false
        }
        return true
    }

    public func action(by meRef: RpgCharacterRef, in gameSession: isolated GameSession)
        async throws
    {
        guard let me = gameSession.game.anyCharacter(at: meRef) else {
            return
        }
        guard let (meleeWeaponToUse, _) = meleeWeapon(for: me) else {
            return
        }
        try await Strike(stepper, with: meleeWeaponToUse, recordStrikeForThisHand: false).action(
            by: meRef)
    }

    private func meleeWeapon<C: RpgCharacterSharedProtocol>(for me: C) -> (
        ref: ItemRef, extraReach: Int?
    )? {
        for readyable in me.equipment {
            if readyable.isReady {
                if let weapon = readyable.core.trueSelf as? any Weapon {
                    if case WeaponRange.melee(let extraReach) = weapon.range {
                        return (ref: weapon.primaryKey, extraReach: extraReach)
                    }
                }
            }
        }
        return nil
    }
}

public enum ReactiveStrikeDecision: Sendable, Equatable, CaseIterable {
    case shouldStrikeReactively
    case shouldNotStrikeReactively
}
