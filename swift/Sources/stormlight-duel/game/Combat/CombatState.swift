public protocol RpgCharacterCombatStateSharedProtocol {
    var turnSpeed: TurnSpeed { get }
    var actionsRemaining: Int { get }
    var weaponsUsed: Set<WeaponName> { get }
    var actionsTaken: Set<CombatActionName> { get }
    var reactionsRemaining: Int { get }
    var recoveriesRemaining: Int { get }
}

public struct RpgCharacterCombatState: RpgCharacterCombatStateSharedProtocol {
    public var turnSpeed: TurnSpeed
    public var actionsRemaining: Int = 0
    public var weaponsUsed: Set<WeaponName> = []
    public var actionsTaken: Set<CombatActionName> = []
    public var reactionsRemaining: Int = 0
    public var recoveriesRemaining: Int = 1

    public var reactionProviders: [Any]

    public init(
        turnSpeed: TurnSpeed,
        actionsRemaining: Int? = nil,
        weaponsUsed: Set<WeaponName>? = nil,
        actionsTaken: Set<CombatActionName>? = nil,
        reactionsRemaining: Int? = nil,
        hasStrikeAdvantageOver: Set<RpgCharacterRef>? = nil,
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.turnSpeed = turnSpeed
        if let actionsRemaining { self.actionsRemaining = actionsRemaining }
        if let weaponsUsed { self.weaponsUsed = weaponsUsed }
        if let actionsTaken { self.actionsTaken = actionsTaken }
        if let reactionsRemaining { self.reactionsRemaining = reactionsRemaining }
        self.reactionProviders = [DodgeProvider(for: characterRef)]
    }

    var snapshot: RpgCharacterCombatStateSnapshot {
        .init(
            turnSpeed: turnSpeed,
            actionsRemaining: actionsRemaining,
            weaponsUsed: weaponsUsed,
            actionsTaken: actionsTaken,
            reactionsRemaining: reactionsRemaining,
            recoveriesRemaining: recoveriesRemaining,
        )
    }
}

public struct RpgCharacterCombatStateSnapshot: RpgCharacterCombatStateSharedProtocol, Sendable {
    public var turnSpeed: TurnSpeed
    public var actionsRemaining: Int
    public var weaponsUsed: Set<WeaponName>
    public var actionsTaken: Set<CombatActionName>
    public var reactionsRemaining: Int
    public var recoveriesRemaining: Int
}
