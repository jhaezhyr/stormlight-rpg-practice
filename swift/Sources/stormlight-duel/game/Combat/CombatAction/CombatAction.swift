public typealias CombatActionName = String

public protocol CombatAction: Sendable {
    static var actionName: CombatActionName { get }
    static var reactionCost: Int { get }
    static var actionCost: Int { get }
    static var focusCost: Int { get }
    var actionName: CombatActionName { get }
    var reactionCost: Int { get }
    var actionCost: Int { get }
    var focusCost: Int { get }
    func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot) -> Bool
    func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession) async
    static func canMaybeTakeAction(
        by character: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool
}
extension CombatAction {
    public func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        canAffordAction(by: characterRef, in: gameSnapshot)
    }
    public static var focusCost: Int { 0 }
    public static var reactionCost: Int { 0 }
    public static var actionCost: Int { 0 }
    public static var actionName: CombatActionName { "\(Self.self)" }
    public var actionName: CombatActionName { Self.actionName }
    public var reactionCost: Int { Self.reactionCost }
    public var actionCost: Int { Self.actionCost }
    public var focusCost: Int { Self.focusCost }
    public func canAffordAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        guard let character = gameSnapshot.characters[characterRef] else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard let combatState = character.combatState else {
            return false
        }
        return character.focus.value >= focusCost && combatState.actionsRemaining >= actionCost
            && combatState.reactionsRemaining >= reactionCost

    }
    public static func canMaybeAffordAction(
        by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool {
        guard let character = gameSnapshot.characters[characterRef] else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard let combatState = character.combatState else {
            return false
        }
        return character.focus.value >= focusCost && combatState.actionsRemaining >= actionCost
            && combatState.reactionsRemaining >= reactionCost
    }
}
extension CombatAction {
    public static func canMaybeTakeAction(
        by character: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool {
        canMaybeAffordAction(by: character, in: gameSnapshot)
    }
}

public enum CombatChoice: Sendable {
    case action(any CombatAction)
    case endTurn
}

extension CombatChoice: CustomStringConvertible {
    public var description: String {
        switch self {
        case .action(let action): "\(action)"
        case .endTurn: "end turn"
        }
    }
}

public let allCombatActions: [CombatAction.Type] = [
    Strike.self, InteractiveMove.self, GainAdvantage.self, Recover.self, DisengageAction.self,
]
