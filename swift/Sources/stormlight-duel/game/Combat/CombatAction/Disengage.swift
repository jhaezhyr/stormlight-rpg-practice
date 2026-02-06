public struct DisengageAction: CombatAction {
    public static let actionCost: Int = 1
    public var direction: Direction1D

    public init(direction: Direction1D) {
        self.direction = direction
    }

    public static func canMaybeTakeAction(
        by character: RpgCharacterRef,
        in gameSnapshot: GameSnapshot
    ) -> Bool {
        // Is this character in range of an enemy?
        let opponents = gameSnapshot.characters.filter { $0.primaryKey != character }
        guard let me = gameSnapshot.characters[character],
            let mySpace = me.combatState?.space
        else {
            return false
        }
        guard
            opponents.filter({
                $0.combatState!.space.expanded(by: $0.reach).touchesOrOverlaps(mySpace)
            }).first != nil
        else {
            return false
        }
        guard me.movementRate > 0 else {
            return false
        }
        guard canMaybeAffordAction(by: character, in: gameSnapshot) else {
            return false
        }
        // TODO Also check if I can go in either direction
        return true
    }
    public func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        guard canAffordAction(by: characterRef, in: gameSnapshot) else {
            return false
        }
        guard let me = gameSnapshot.characters[characterRef],
            let mySpace = me.combatState?.space
        else {
            return false
        }
        let opponents = gameSnapshot.characters.filter { $0.primaryKey != characterRef }
        guard
            opponents.filter({
                $0.combatState!.space.expanded(by: $0.reach).touchesOrOverlaps(mySpace)
            }).first != nil
        else {
            return false
        }
        guard let map = (gameSnapshot.scene as? Combat)?.map else {
            return false
        }
        let impassableSpaces = opponents.map { $0.combatState!.space } + map.staticObstacles
        let newSpace = mySpace + (direction == .right ? 5 : -5)
        guard impassableSpaces.allSatisfy({ !$0.overlaps(newSpace) }) else {
            return false
        }
        return true
    }
    public func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession) async
    {
        guard let me = gameSession.game.anyCharacter(at: characterRef),
            let mySpace = me.combatState?.space
        else {
            return
        }
        let newSpace = mySpace + (direction == .right ? 5 : -5)
        me.combatState!.space = newSpace
        await gameSession.game.naiveDispatch(
            MoveHook.stepped(direction: direction, carefully: true),
            for: characterRef,
            in: gameSession
        )
    }
}
