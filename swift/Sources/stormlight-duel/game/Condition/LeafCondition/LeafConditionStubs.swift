// I just made every condition into a ConditionSnapshot too. I'm pretty sure these are all stateless.

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
