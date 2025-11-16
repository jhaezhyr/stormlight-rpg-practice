public protocol ConditionProtocol: ListenerHolder, SelfListenerHolder, SelfListenerSelfHookHolder {
    associatedtype C: ConditionType
    var type: C { get }
    var id: Int { get }
}
extension ConditionProtocol {
    public var allListeners: [any ListenerProtocol] {
        listeners + type.listeners
    }
    public var allSelfListeners: [any SelfListenerProtocol] {
        selfListeners + type.selfListeners
    }
    public var allSelfListenersSelfHooks: [any SelfListenerSelfHookProtocol] {
        selfListenersSelfHooks + type.selfListenersSelfHooks
    }
}

public struct AnyConditionType: ConditionType {
    public var core: any ConditionType
    public func hash(into hasher: inout Hasher) {
        hasher.combine(core)
    }
    public static func == (lh: Self, rh: Self) -> Bool {
        // FIXME
        return false
    }
}

public struct AnyCondition: ConditionProtocol {
    public var core: any ConditionProtocol
    public var type: AnyConditionType { AnyConditionType(core: core.type) }
    public var id: Int { core.id }
}

public struct DurationCondition<C: ConditionType>: Equatable, ConditionProtocol {
    public var type: C
    public var id: Int
    public var durationRemainingInTurns: Int
    public var selfListenersSelfHooks: [any SelfListenerSelfHookProtocol] {
        [
            selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) { game, character in
                guard
                    let (myIndex, meUntyped) = character.conditions.enumerated().first(where: {
                        (i, c) in
                        c.id == self.id
                    }),
                    var me = meUntyped as? Self
                else {
                    return
                }
                // TODO 99% of this function is boilerplate. However, we're not ready to pin ourselves down to one access mechanism for conditions yet.
                me.durationRemainingInTurns -= 1
                if durationRemainingInTurns <= 0 {
                    character.conditions.remove(at: myIndex)
                } else {
                    character.conditions[myIndex] = me
                }
            }
        ]
    }

    public init(type: C, duration: Int) {
        self.type = type
        self.durationRemainingInTurns = duration
        self.id = Int.random(in: Int.min...Int.max)
    }

    // It's cool! But it doesn't allow us to observe the duration.
    static func getDurationListener<Con: ConditionProtocol>(condition: Con) -> SelfListenerSelfHook<
        CombatPhase, AnyRpgCharacter
    > {
        return {
            var durationRemainingInTurns = 0
            return selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) {
                game, character in
                guard
                    let myIndex = character.conditions.firstIndex(where: { c in c.id == condition.id
                    })
                else {
                    return
                }
                // TODO 50% of this function is boilerplate. However, we're not ready to pin ourselves down to one access mechanism for conditions yet.
                durationRemainingInTurns -= 1
                if durationRemainingInTurns <= 0 {
                    character.conditions.remove(at: myIndex)
                }
            }
        }()
    }
}

public protocol ConditionType: Hashable, ListenerHolderLeaf, SelfListenerHolderLeaf,
    SelfListenerSelfHookHolderLeaf, SelfListenerSelfHookForTestHolderLeaf
{
}

public struct Afflicted: ConditionType {
    public let damagePerTurn: Damage
    public init(damagePerTurn: Damage) {
        self.damagePerTurn = damagePerTurn
    }
    public var selfListenersSelfHooks: [any SelfListenerSelfHookProtocol] {
        [
            selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) { game, me in
                me.takeDamage(damagePerTurn)
            }
        ]
    }

    // TODO This condition can have multiple equivalent stacks; need to handle that
}
public struct Determined: ConditionType {
    public var selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] {
        [
            selfListen(
                toMyTests: TestHookType.afterFailure,
                as: AnyRpgCharacter.self,
                testType: AnyRpgTest.self
            ) {
                game, character, test in
                test.advantages += 1
                character.conditions.removeAll { c in c.type as? Self == self }
            }
        ]
    }
}

public struct Disoriented: ConditionType {}
public struct Empowered: ConditionType {}
public struct Enhanced: ConditionType {
    public var stat: AttributeName
    public var amount: Int
}
public struct Exhausted: ConditionType {
    public var amount: Int
}
public struct Focused: ConditionType {}
public struct Immobilized: ConditionType {}
public struct Prone: ConditionType {}
public struct Restrained: ConditionType {}
public struct Slowed: ConditionType {}
public struct Stunned: ConditionType {}
public struct Surprised: ConditionType {}
public struct Unconscious: ConditionType {}
