public struct Level1CpuBrain: RpgCharacterBrain {
    public let meRef: RpgCharacterRef

    public init(for meRef: RpgCharacterRef) {
        self.meRef = meRef
    }

    public func decide<C>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C: Sendable {
        return options.first!
    }

    public func decide<T>(
        _ code: DecisionCode,
        nonIterableType: T.Type,
        in gameSnapshot: GameSnapshot
    ) async
        -> T
    where T: Sendable {
        let me = gameSnapshot.characters[meRef]!
        if T.self == CombatChoice.self {
            for enemy in gameSnapshot.enemies(of: meRef) {
                for weapon in me.readyItems.compactMap({ $0.core as? any WeaponSnapshot }) {
                    let strike = Strike(enemy, with: weapon.primaryKey)
                    if strike.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                        return CombatChoice.action(strike) as! T
                    }
                }
            }
            return CombatChoice.endTurn as! T
        }
        fatalError("Level 1 brain doesn't know how to decide on \(nonIterableType) values")
    }

    public func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message {
    }

    public func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async {
    }
}
