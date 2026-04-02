public struct Mark2CpuBrain: RpgCharacterBrain {
    public let meRef: RpgCharacterRef

    public init(for meRef: RpgCharacterRef) {
        self.meRef = meRef
    }

    public func decide<C>(_ code: DecisionCode, options: C, in gameSnapshot: GameSnapshot) async
        -> C.Element
    where C: Collection, C: Sendable {
        switch code {
        case .skillForGainAdvantage:
            decideGainAdvantageSkill(
                options: options.map { $0 as! CoreSkillName },
                in: gameSnapshot
            ) as! C.Element
        case .drawWeaponsChoice(let hand):
            decideWeaponToDraw(
                hand: hand, options: options.map { $0 as! DrawWeaponDecision }, in: gameSnapshot)
                as! C.Element
        case .directionToMove5Ft:
            decideStepChoice(
                options: options.map { $0 as! DecideOrOther<Direction1D> }, in: gameSnapshot)
                as! C.Element
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
        let snapshot = MySnapshot(meRef: meRef, game: gameSnapshot)
        let me = snapshot.me
        /// This brain's priorities are as follows
        /// 1. If I have lost enough focus+health than my recovery die can provide, then use the recover action.
        /// 2. If I am not in optimal range of using my "best weapon" on my opponent, then move.
        /// 3. If I am in optimal range of my opponent, but not wielding my "best weapon", then draw it.
        /// 4. If I am in optimal range of my opponent, with 2+ actions left on my turn, then gain advantage. Use the trait with the highest bonus, except the one that corresponds to my "best weapon".
        /// 5. If I have one action left, and I can strike, then strike!
        /// 6. If I have any spare actions left, then I gain advantage.
        let lostFocusAndHealth =
            me.focus.maxValue - me.focus.value + me.health.maxValue - me.health.value
        if me.recoveryDie.max <= lostFocusAndHealth {
            let potentialAction = InteractiveRecover()
            if potentialAction.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                return .action(potentialAction)
            }
        }
        let primeSpace = snapshot.bestStrikingSpace
        if !me.combatState!.space.overlaps(primeSpace) && me.movementRate > 0 {
            let potentialAction = InteractiveMove()
            if potentialAction.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                return .action(potentialAction)
            }
        } else {
            if snapshot.me.mainHand != snapshot.bestWeapon.primaryKey {
                let potentialAction = InteractiveDrawWeapons()
                if potentialAction.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                    return .action(potentialAction)
                }
            }
            if me.combatState!.actionsRemaining >= 2 {
                let potentialAction = InteractiveGainAdvantage(
                    opponent: snapshot.bestEnemy.primaryKey, chosenSkill: nil)
                if potentialAction.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                    return .action(potentialAction)
                }
            }
        }
        if let strike = snapshot.bestAvailableStrike {
            let potentialAction = strike
            if potentialAction.canReallyTakeAction(by: meRef, in: gameSnapshot) {
                return .action(potentialAction)
            }
        }
        let potentialAction = InteractiveGainAdvantage(
            opponent: snapshot.bestEnemy.primaryKey, chosenSkill: nil)
        if potentialAction.canReallyTakeAction(by: meRef, in: gameSnapshot) {
            return .action(potentialAction)
        }
        return CombatChoice.endTurn
    }

    public func decideGraze(in gameSnapshot: GameSnapshot) -> GrazeChoice {
        /// When should we graze?
        /// 1. If the damage I would do (after accounting for deflect) is 0, then don't graze.
        /// 2. If the damage I would do (after accounting for deflect) is enough to defeat them, then graze.
        /// 3. If I am within one strike of death, don't graze.
        /// 4. Otherwise, there's a 67:33 chance I graze.
        let filledSnapshot = MySnapshot(meRef: meRef, game: gameSnapshot)
        let guessCurrentWeapon = filledSnapshot.bestWeapon
        let guessTarget = filledSnapshot.consciousEnemies.first!
        let guessMinGrazeDamage = guessCurrentWeapon.damage.min - guessTarget.deflect
        if guessMinGrazeDamage <= 0 {
            return .shouldNotGraze
        }
        if guessMinGrazeDamage >= guessTarget.health.value {
            return .shouldGraze
        }
        return (Int.random(in: 1...2) <= 1) ? .shouldGraze : .shouldNotGraze
    }

    public func decideGainAdvantageSkill(options: [CoreSkillName], in gameSnapshot: GameSnapshot)
        -> CoreSkillName
    {
        let filledSnapshot = MySnapshot(meRef: meRef, game: gameSnapshot)
        let guessedWeapon = filledSnapshot.bestWeapon
        let sorted = options.filter {
            $0 != (guessedWeapon.weaponsSkill == .heavy ? .heavyWeaponry : .lightWeaponry)
        }.sorted(byMappedValue:) {
            skill in
            filledSnapshot.me.modifiersForCoreSkills[skill]
        }
        return sorted.randomElement()!
    }

    public func decideStepChoice(
        options: [DecideOrOther<Direction1D>], in gameSnapshot: GameSnapshot
    ) -> DecideOrOther<Direction1D> {
        let snapshot = MySnapshot(meRef: meRef, game: gameSnapshot)
        let currentSpace = snapshot.me.combatState!.space
        let goalSpace = snapshot.bestStrikingSpace
        let goal = goalSpace.origin  // The furthest spot from my enemy, but still in the space.
        let here = currentSpace.facing(snapshot.bestStrikingSpace.orientation).origin  // Still my furthest point from my enemy
        let candidate = goal < here ? Direction1D.left : goal > here ? .right : nil
        if let candidate, options.contains(DecideOrOther<Direction1D>.decide(candidate)) {
            return DecideOrOther.decide(candidate)
        } else if let other = options.first(where: {
            if case .other(_) = $0 { true } else { false }
        }) {
            return other
        } else {
            return options.randomElement()!
        }
    }

    public func decideDodge(in gameSnapshot: GameSnapshot) -> ShouldDodgeChoice {
        /// When should I dodge?
        /// 1. If the minimum damage done by a hit (after accounting for deflect) would defeat me, then dodge.
        /// 2. Otherwise, there's a 67:33 chance I dodge
        let mySnapshot = MySnapshot(meRef: meRef, game: gameSnapshot)
        let guessAttacker = mySnapshot.consciousEnemies.first!
        let attackerSnapshot = MySnapshot(meRef: guessAttacker.primaryKey, game: gameSnapshot)
        let guessCurrentWeapon = attackerSnapshot.bestWeapon
        let guessMinHitDamage =
            guessCurrentWeapon.minHitDamage(by: mySnapshot.me) - mySnapshot.me.deflect
        if guessMinHitDamage >= mySnapshot.me.health.value {
            return .shouldDodge
        }
        return (Int.random(in: 1...2) <= 1) ? .shouldDodge : .shouldNotDodge
    }

    public func decideWeaponToDraw(hand: Hand, options: [DrawWeaponDecision], in game: GameSnapshot)
        -> DrawWeaponDecision
    {
        let snapshot = MySnapshot(meRef: meRef, game: game)
        let bestWeapon = snapshot.bestWeapon
        if let option = options.first(where: {
            if case .weapon(let draw) = $0, draw.weaponId == bestWeapon.primaryKey {
                return true
            } else {
                return false
            }
        }) {
            return option
        }
        return options.randomElement()!
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
        var consciousEnemies: [any RpgCharacterSnapshot] {
            game.opponents(of: meRef, conscious: true)
        }
        var bestEnemy: any RpgCharacterSnapshot {
            consciousEnemies.first!
        }
        let game: GameSnapshot
        var bestWeapon: any WeaponSnapshot {
            /// The best weapon is chosen as follows:
            /// 1. The weapon with the highest average striking damage.
            /// 2. In case of a tie, the weapon with a ranged attack.
            /// 3. In case of a tie, the wapon with extra reach.
            let allWeapons = me.equipment.compactMap { $0.core.trueSelf as? any WeaponSnapshot }
            let sortedWeapons = allWeapons.sorted { w in w.averageHitDamage(by: me) }
            return sortedWeapons.last!
        }
        var bestAvailableStrike: Strike? {
            let all = Strike.possibleStrikes(for: meRef, in: game).map {
                FilledStrike($0, by: me, in: game)
            }
            let sorted = all.sorted(byMappedValue: { $0.weapon.averageHitDamage(by: me) })
            return sorted.last?.core
        }
        var bestStrikingSpace: Space1D {
            let bestEnemy = self.bestEnemy
            let bestEnemySpace = bestEnemy.combatState!.space
            let meSpace = me.combatState!.space
            let amIToTheLeftOfEnemy = meSpace.lo < bestEnemySpace.lo
            let bestWeapon = self.bestWeapon
            let maxLeft = -80
            let maxRight = 80
            switch bestWeapon.range {
            case .melee(let extraReach):
                let width = (meSpace.size + (extraReach ?? 0))
                if amIToTheLeftOfEnemy {
                    return Space1D(
                        origin: max(maxLeft, bestEnemySpace.lo - width), size: width,
                        orientation: .right)
                } else {
                    return Space1D(
                        origin: min(maxRight, bestEnemySpace.hi + width), size: width,
                        orientation: .left)
                }
            case .ranged(let short, long: _):
                let tooClose = 5
                let width = (meSpace.size + short)
                if amIToTheLeftOfEnemy {
                    return Space1D(
                        origin: max(maxLeft, bestEnemySpace.lo - width), size: width - tooClose,
                        orientation: .right)
                } else {
                    return Space1D(
                        origin: min(maxRight, bestEnemySpace.hi + width), size: width - tooClose,
                        orientation: .left)
                }
            }
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
    var max: Int {
        dice.map { $0.die.max * ($0.count) }.reduce(0, +)
    }
    var min: Int {
        dice.map { $0.die.min * ($0.count) }.reduce(0, +)
    }
}

extension NumberDie {
    var average: Double {
        (Double(rawValue) - 1) / 2
    }
    var max: Int {
        rawValue
    }
    var min: Int {
        1
    }
}

extension WeaponSharedProtocol {
    func averageHitDamage(by me: any RpgCharacterSharedProtocol) -> Double {
        self.damage.average
            + Double(
                me.modifiersForCoreSkills[
                    self.weaponsSkill == .heavy ? .heavyWeaponry : .lightWeaponry])

    }
    func minHitDamage(by me: any RpgCharacterSharedProtocol) -> Int {
        self.damage.min
            + me.modifiersForCoreSkills[
                self.weaponsSkill == .heavy ? .heavyWeaponry : .lightWeaponry]

    }
    func maxHitDamage(by me: any RpgCharacterSharedProtocol) -> Int {
        self.damage.max
            + me.modifiersForCoreSkills[
                self.weaponsSkill == .heavy ? .heavyWeaponry : .lightWeaponry]

    }
}

private struct FilledStrike {
    let core: Strike
    let attacker: any RpgCharacterSnapshot
    let target: any RpgCharacterSnapshot
    let weapon: any WeaponSnapshot
    let weaponIsReady: Bool
    init(_ core: Strike, by me: any RpgCharacterSnapshot, in game: GameSnapshot) {
        self.core = core
        self.attacker = me
        self.target = game.characters[core.target]!
        let readyable = attacker.equipment[core.weaponToStrikeWith]!
        self.weaponIsReady = readyable.isReady
        self.weapon = readyable.core.trueSelf as! any WeaponSnapshot
    }
}
