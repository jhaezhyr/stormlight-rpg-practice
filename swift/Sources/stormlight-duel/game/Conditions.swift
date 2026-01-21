// I just made every condition into a ConditionSnapshot too. I'm pretty sure these are all stateless.

public struct DurationCondition<C: Condition & ConditionSnapshot>: CompositeCondition,
    ConditionSnapshot
{
    public var core: C
    public var durationRemainingInTurns: Int
    public let selfListenersSelfHooks: [any SelfListenerSelfHookProtocol]

    public init(core: C, duration: Int, in gameSession: isolated GameSession) {
        let id = core.id
        self.core = core
        self.durationRemainingInTurns = duration
        self.selfListenersSelfHooks = [
            gameSession.selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) {
                gameSession, character in
                guard var me = character.conditions[id]?.core as? Self else {
                    fatalError(
                        "Why is this condition happening to a character without this condition?")
                }
                me.durationRemainingInTurns -= 1
                if me.durationRemainingInTurns <= 0 {
                    character.conditions.remove(id)
                } else {
                    character.conditions[id] = AnyCondition(me)
                }
            }
        ]
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

public protocol ConditionSharedProtocol {
    var id: Int { get }
}
public protocol Condition: ConditionSharedProtocol {
    var snapshot: any ConditionSnapshot { get }
}

public protocol ConditionSnapshot: Sendable, ConditionSharedProtocol {
}
extension Condition where Self: ConditionSnapshot {
    public var snapshot: ConditionSnapshot { self }
}

/// Cannot hold one itself recursively. `AnyCondition(AnyCondition(someCondition)).core === someCondition`
public struct AnyCondition: Condition {
    public var core: any Condition
    public var id: Int { core.id }
    public var snapshot: any ConditionSnapshot { core.snapshot }
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

public struct AnyConditionSnapshot: ConditionSnapshot {
    public var core: any ConditionSnapshot
    public var id: Int { core.id }
    private init(notUnwrapping conditionSnapshot: any ConditionSnapshot) {
        self.core = conditionSnapshot
    }
    public init(_ conditionSnapshot: any ConditionSnapshot) {
        if let conditionSnapshot = conditionSnapshot as? AnyConditionSnapshot {
            self.init(conditionSnapshot)
        } else {
            self.init(notUnwrapping: conditionSnapshot)
        }
    }
}
extension AnyConditionSnapshot: Keyed {
    public var primaryKey: Int { id }
}

public struct Afflicted: LeafCondition, ConditionSnapshot {
    public let id: Int
    public let damagePerTurn: Damage
    public init(damagePerTurn: Damage, in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
        self.damagePerTurn = damagePerTurn
        self.selfListenersSelfHooks = [
            gameSession.selfListen(toMy: CombatPhase.endOfTurn, as: AnyRpgCharacter.self) {
                game, me in
                me.takeDamage(damagePerTurn)
            }
        ]
    }
    public let selfListenersSelfHooks: [any SelfListenerSelfHookProtocol]

    // TODO This condition can have multiple equivalent stacks; need to handle that
}
public struct Determined: LeafCondition, ConditionSnapshot {
    public let id: Int
    public let selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol]
    public init(in gameSession: isolated GameSession) {
        let id = gameSession.nextId()
        self.id = id
        self.selfListenersSelfHooksForTests = [
            gameSession.selfListen(
                toMyTests: TestHookType.afterFailure,
                as: AnyRpgCharacter.self,
                testType: AnyRpgTest.self
            ) {
                game, character, test in
                test.advantages += 1
                character.conditions.remove(id)
            }
        ]
    }
}

public struct Disoriented: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Empowered: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Enhanced: LeafCondition, ConditionSnapshot {
    public let id: Int
    public var stat: AttributeName
    public var amount: Int
    public init(stat: AttributeName, amount: Int, in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
        self.stat = stat
        self.amount = amount
    }
}
public struct Exhausted: LeafCondition, ConditionSnapshot {
    public let id: Int
    public var amount: Int
    public init(amount: Int, in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
        self.amount = amount
    }
}
public struct Focused: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Immobilized: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Prone: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Restrained: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Slowed: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Stunned: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Surprised: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Unconscious: LeafCondition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
