public typealias CombatActionName = String

public protocol CombatAction: Sendable, SendableMetatype {
    static var actionName: CombatActionName { get }
    static var reactionCost: Int { get }
    static var actionCost: Int { get }
    static var focusCost: Int { get }
    static var canBeTakenMoreThanOncePerTurn: Bool { get }
    var actionName: CombatActionName { get }
    var reactionCost: Int { get }
    var actionCost: Int { get }
    func focusCost(in gameSnapshot: GameSnapshot) -> Int
    /// Assuming actionCost, reactionCost, focusCost can be satisfied, and an action of this name hasn't already been taken this turn or it can be taken multiple times this turn, can this action be taken this turn?
    ///
    /// This is for overriding only. It shouldn't be called to see if the action can be taken. That's what canReallyTakeAction is for.
    func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot) -> Bool
    /// Does the action. Does not cost actions, focus, or reactions; use `reallyTakeAction` for that.
    ///
    /// This is for overriding, or for special cases where the action can be taken without cost.
    func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession) async throws
    /// Returns `true` if some instance of the type could be constructed that would satisfy `self.canTakeAction(by:character, in:gameSnapshot)`.
    ///
    /// Override to provide checks beyond just actionCost, reactionCost, focusCost, and whether this action can be taken multiple times in a turn.
    ///
    /// This is for overriding only. It shouldn't be called to see if the action can be taken. That's what canReallyMaybeTakeAction is for.
    static func canMaybeTakeAction(
        by character: RpgCharacterRef,
        in gameSnapshot: GameSnapshot
    ) -> Bool
}

// TODO We could pass character object, instead of a character ref, to the overrideable functions.

// Defaults
extension CombatAction {
    public static var focusCost: Int { 0 }
    public static var reactionCost: Int { 0 }
    public static var actionCost: Int { 0 }
    public static var actionName: CombatActionName { "\(Self.self)" }
    public var actionName: CombatActionName { Self.actionName }
    public var reactionCost: Int { Self.reactionCost }
    public var actionCost: Int { Self.actionCost }
    public func focusCost(in gameSnapshot: GameSnapshot) -> Int {
        Self.focusCost
    }
    public static var canBeTakenMoreThanOncePerTurn: Bool { false }
    public static func canMaybeTakeAction(
        by character: RpgCharacterRef,
        in gameSnapshot: GameSnapshot
    ) -> Bool { true }
    public func canTakeAction(
        by characterRef: RpgCharacterRef,
        in gameSnapshot: GameSnapshot
    ) -> Bool {
        Self.canMaybeTakeAction(by: characterRef, in: gameSnapshot)
    }
}

// Helper functions
extension CombatAction {
    public func canAffordAction(
        by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot
    )
        -> Bool
    {
        guard let character = gameSnapshot.characters[characterRef] else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard let combatState = character.combatState else {
            return false
        }
        return character.focus.value >= focusCost(in: gameSnapshot)
            && combatState.actionsRemaining >= actionCost
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
        return character.focus.value >= focusCost
            && combatState.actionsRemaining >= actionCost
            && combatState.reactionsRemaining >= reactionCost
    }

    public static func canBeTakenAgainThisTurn(
        by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot
    ) -> Bool {
        if self.canBeTakenMoreThanOncePerTurn {
            return true
        }
        guard let character = gameSnapshot.characters[characterRef] else {
            return false
        }
        return !character.combatState!.actionsTaken.contains(Self.actionName)
    }
}

// True public functions
extension CombatAction {
    /// "Really" includes actionCost, reactionCost, focusCost, and whether this action can be taken multiple times in a turn.
    public func canReallyTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        canAffordAction(by: characterRef, in: gameSnapshot)
            && Self.canBeTakenAgainThisTurn(by: characterRef, in: gameSnapshot)
            && canTakeAction(by: characterRef, in: gameSnapshot)
    }
    /// "Really" includes actionCost, reactionCost, focusCost, and whether this action can be taken multiple times in a turn.
    public static func canReallyMaybeTakeAction(
        by character: RpgCharacterRef, in gameSnapshot: GameSnapshot

    ) -> Bool {
        canMaybeAffordAction(by: character, in: gameSnapshot)
            && canBeTakenAgainThisTurn(by: character, in: gameSnapshot)
            && canMaybeTakeAction(by: character, in: gameSnapshot)
    }
    /// "Really" means it does the costs and logs the actionName. Assumes you canReallyTakeAction.
    public func reallyTakeAction(
        by characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) async throws {
        guard let character = gameSession.game.anyCharacter(at: characterRef) else {
            return
        }
        character.focus.value -= focusCost(in: gameSession.game.snapshot())
        character.combatState!.actionsTaken.insert(actionName)
        character.combatState!.actionsRemaining -= actionCost
        character.combatState!.reactionsRemaining -= reactionCost

        try await gameSession.game.dispatch(
            CombatActionEvent(characterRef: characterRef, action: self))

        try await action(by: characterRef, in: gameSession)
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
    Strike.self,
    InteractiveMove.self,
    InteractiveGainAdvantage.self,
    InteractiveRecover.self,
    DisengageAction.self,
]
