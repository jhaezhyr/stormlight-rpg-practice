public struct DurationCondition<C: Condition>: CompositeCondition {
    public var core: C
    public var durationRemainingInTurns: Int
    public var selfListenersSelfHooks: [any SelfListenerSelfHookProtocol] {
        [
            selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) { game, character in
                guard character.conditions.contains(self.id) else {
                    fatalError(
                        "Why is this condition happening to a character without this condition?")
                }
                var me = self
                me.durationRemainingInTurns -= 1
                if me.durationRemainingInTurns <= 0 {
                    character.conditions.remove(self.id)
                } else {
                    character.conditions[self.id] = AnyCondition(me)
                }
            }
        ]
    }

    public init(core: C, duration: Int) {
        self.core = core
        self.durationRemainingInTurns = duration
    }

    // It's cool! But it doesn't allow us to observe the duration.
    static func getDurationListener<Con: Condition>(condition: Con)
        -> SelfListenerSelfHook<
        CombatPhase, AnyRpgCharacter
        >
    {
        return {
            var durationRemainingInTurns = 0
            return selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) {
                game, character in
                guard character.conditions.contains(condition.id) else {
                    return
                }
                // TODO 50% of this function is boilerplate. However, we're not ready to pin ourselves down to one access mechanism for conditions yet.
                durationRemainingInTurns -= 1
                if durationRemainingInTurns <= 0 {
                    character.conditions.remove(condition.id)
                }
            }
        }()
    }
}

private protocol CompositeCondition: Condition, NonLeafGenericListenerHolder, AllTheListenersHolder
{
    associatedtype C: Condition
    var core: C { get }
}
extension CompositeCondition {
    public var id: Int { core.id }
    public var childHolders: [Any] { [core] }
}

private protocol LeafCondition: Condition, ListenerHolderLeaf, SelfListenerHolderLeaf,
    SelfListenerSelfHookHolderLeaf, SelfListenerSelfHookForTestHolderLeaf
{
}

public protocol Condition {
    var id: Int { get }
}

/// Cannot hold one itself recursively. `AnyCondition(AnyCondition(someCondition)).core === someCondition`
public struct AnyCondition: Condition {
    public var core: any Condition
    public var id: Int { core.id }
    private init(notUnwrapping character: any Condition) {
        self.core = character
    }
    public init(_ character: any Condition) {
        if let character = character as? AnyCondition {
            self.init(character)
        } else {
            self.init(notUnwrapping: character)
        }
    }
}

extension AnyCondition: Keyed {
    public var primaryKey: Int { id }
}

nonisolated(unsafe) private var nextConditionId = 0
private func getNextConditionId() -> Int {
    nextConditionId += 1
    return nextConditionId
}

public struct Afflicted: LeafCondition {
    public var id: Int = getNextConditionId()
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
public struct Determined: LeafCondition {
    public var id: Int = getNextConditionId()
    public var selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol] {
        [
            selfListen(
                toMyTests: TestHookType.afterFailure,
                as: AnyRpgCharacter.self,
                testType: AnyRpgTest.self
            ) {
                game, character, test in
                test.advantages += 1
                character.conditions.remove(self.id)
            }
        ]
    }
}

public struct Disoriented: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Empowered: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Enhanced: LeafCondition {
    public var id: Int = getNextConditionId()
    public var stat: AttributeName
    public var amount: Int
}
public struct Exhausted: LeafCondition {
    public var id: Int = getNextConditionId()
    public var amount: Int
}
public struct Focused: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Immobilized: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Prone: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Restrained: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Slowed: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Stunned: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Surprised: LeafCondition {
    public var id: Int = getNextConditionId()
}
public struct Unconscious: LeafCondition {
    public var id: Int = getNextConditionId()
}
