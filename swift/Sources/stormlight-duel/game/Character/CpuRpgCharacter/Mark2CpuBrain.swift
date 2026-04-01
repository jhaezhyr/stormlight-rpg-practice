/// This brain's priorities are as follows
/// 1. If I have lost enough focus+health than my recovery die can provide, then use the recover action.
/// 2. If I am not in optimal range of using my "best weapon" on my opponent, then move.
/// 3. If I am in optimal range of my opponent, but not wielding my "best weapon", then draw it.
/// 4. If I am in optimal range of my opponent, with 2+ actions left on my turn, then gain advantage. Use the trait with the highest bonus, except the one that corresponds to my "best weapon".
/// 5. If I have one action left, and I can strike, then strike!
/// 6. If I have any spare actions left, then I gain advantage.
///
/// The best weapon is chosen as follows:
/// 1. The weapon with the highest average striking damage.
/// 2. In case of a tie, the weapon with a ranged attack.
/// 3. In case of a tie, the wapon with extra reach.
///
/// When should we graze?
/// 1. If the damage I would do (after accounting for deflect) is 0, then don't graze.
/// 2. If the damage I would do (after accounting for deflect) is enough to defeat them, then graze.
/// 3. If I am within one strike of death, don't graze.
/// 4. Otherwise, there's a 67:33 chance I graze.
///
/// When should I dodge?
/// 1. If the minimum damage done by a hit (after accounting for deflect) would defeat me, then dodge.
/// 2. Otherwise, there's a 67:33 chance I dodge.

public struct Mark2CpuBrain: RpgCharacterBrain {
    public let meRef: RpgCharacterRef

    public init(for meRef: RpgCharacterRef) {
        self.meRef = meRef
    }

    public func decide<C>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C: Sendable {
        switch code {
        case .shouldDodge:
            decideDodge(in: gameSnapshot) as! C.Element
        case .shouldGraze:
            decideGraze(in: gameSnapshot) as! C.Element
        default:
            options.first!
        }
    }

    public func decide<T>(
        _ code: DecisionCode,
        nonIterableType: T.Type,
        in gameSnapshot: GameSnapshot
    ) async
        -> T
    where T: Sendable {
        if T.self == CombatChoice.self {
            return decideCombatAction(in: gameSnapshot) as! T
        }
        fatalError("Level 1 brain doesn't know how to decide on \(nonIterableType) values")
    }

    public func decideCombatAction(in gameSnapshot: GameSnapshot) -> CombatChoice {
        let me = gameSnapshot.characters[meRef]!
        for enemy in gameSnapshot.opponentRefs(of: meRef) {
            for weapon in me.readyItems.compactMap({ $0.core as? any WeaponSnapshot }) {
                let strike = Strike(enemy, with: weapon.primaryKey)
                if strike.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                    return CombatChoice.action(strike)
                }
            }
        }
        return CombatChoice.endTurn

    }

    public func decideGraze(in gameSnapshot: GameSnapshot) -> GrazeChoice {

    }

    public func decideDodge(in gameSnapshot: GameSnapshot) -> ShouldDodgeChoice {

    }

    public func hear<M>(_ message: M, in gameSnapshot: GameSnapshot) async where M: Message {
    }

    public func hearHint(_ message: String, in gameSnapshot: GameSnapshot) async {
    }
}

extension Mark2CpuBrain {
    struct MySnapshot {
        let meRef: RpgCharacterRef
        var me: any RpgCharacterSnapshot {
            game.characters[meRef]!
        }
        let game: GameSnapshot
        var bestWeapon: any WeaponSnapshot {
            let allWeapons = me.equipment.compactMap { $0.core.trueSelf as? any WeaponSnapshot }
            let sortedWeapons = allWeapons.sorted { w in w.averageDamage(by: me) }
            return sortedWeapons.last!
        }
        var bestAvailableStrike: Strike? {
        }
    }
}

extension Collection {
    func sorted<Value: Comparable>(byMappedValue: (Element) -> Value) -> [Element] {
        return self.map { ($0, byMappedValue($0)) }.sorted { (lh, rh) in lh.1 < rh.1 }.map { $0.0 }
    }
}

extension RandomDistribution {
    var average: Double {
        dice.map { $0.die.average * Double($0.count) }.reduce(0, +)
    }
}

extension NumberDie {
    var average: Double {
        (Double(rawValue) - 1) / 2
    }
}

extension WeaponSharedProtocol {
    func averageDamage(by me: any RpgCharacterSharedProtocol) -> Double {
        self.damage.average
            + Double(
                me.modifiersForCoreSkills[
                    self.weaponsSkill == .heavy ? .heavyWeaponry : .lightWeaponry])

    }
}
