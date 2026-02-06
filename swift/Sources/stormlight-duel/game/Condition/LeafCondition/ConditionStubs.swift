// I just made every condition into a ConditionSnapshot too. I'm pretty sure these are all stateless.

public struct Disoriented: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Empowered: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Enhanced: Condition, ConditionSnapshot {
    public let id: Int
    public var stat: AttributeName
    public var amount: Int
    public init(stat: AttributeName, amount: Int, in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
        self.stat = stat
        self.amount = amount
    }
}
public struct Exhausted: Condition, ConditionSnapshot {
    public let id: Int
    public var amount: Int
    public init(amount: Int, in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
        self.amount = amount
    }
}
public struct Focused: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Immobilized: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Prone: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Restrained: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Slowed: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Stunned: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Surprised: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
public struct Unconscious: Condition, ConditionSnapshot {
    public let id: Int
    public init(in gameSession: isolated GameSession) {
        self.id = gameSession.nextId()
    }
}
