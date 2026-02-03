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

    public func decide<T>(_ code: DecisionCode, type: T.Type, in gameSnapshot: GameSnapshot) async
        -> T
    where T: Sendable {
        let me = gameSnapshot.characters[meRef]!
        if T.self == CombatChoice.self {
            for enemy in gameSnapshot.enemies(of: meRef) {
                for weapon in me.readyItems.compactMap({ $0.core as? any WeaponSnapshot }) {
                    let strike = Strike(enemy, with: weapon.primaryKey)
                    if strike.canTakeAction(by: meRef, in: gameSnapshot) {
                        print(
                            "Kal: Attacking \(enemy.name) with \(weapon.name) (\(weapon.weaponName))"
                        )
                        return CombatChoice.action(strike) as! T
                    }
                }
            }
            return CombatChoice.endTurn as! T
        }
        fatalError("Level 1 brain doesn't know how to decide on \(type) values")
    }
}
