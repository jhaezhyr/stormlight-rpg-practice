public struct Strike: CombatAction {
    public static func actionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        1
    }
    public static var canBeTakenMoreThanOncePerTurn: Bool { true }
    public var weaponToStrikeWith: ItemRef
    public var recordStrikeForThisHand: Bool
    public var target: RpgCharacterRef
    public func focusCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot) -> Int {
        guard let character = gameSnapshot.characters[characterRef]?.core,
            let readyableItem = character.equipment[weaponToStrikeWith],
            let weapon = readyableItem.core.core as? any WeaponSnapshot
        else {
            return 0  // This is actually some kind of error state.
        }
        let isTwoHanded = weapon.traits.contains { $0.trait is TwoHanded }
        let isOffHandStrike = (character.offHand == weaponToStrikeWith && !isTwoHanded)
        if isOffHandStrike {
            let isOffhandWeapon = weapon.activeTraits(
                whenEquippedBy: characterRef, in: gameSnapshot
            ).contains(where: { $0 is Offhand })
            return isOffhandWeapon ? 1 : 2
        } else {
            return 0
        }
    }

    public init(
        _ target: RpgCharacterRef,
        with weaponToStrikeWith: ItemRef,
        recordStrikeForThisHand: Bool = true
    ) {
        self.target = target
        self.weaponToStrikeWith = weaponToStrikeWith
        self.recordStrikeForThisHand = recordStrikeForThisHand
    }

    public func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        guard let character = gameSnapshot.characters[characterRef]?.core else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard let readyableItem = character.equipment[weaponToStrikeWith]
        else {
            return false
        }
        guard let weapon = readyableItem.core.core as? any WeaponSnapshot else {
            return false
        }
        guard
            gameSnapshot.characters[target] != nil,
            target != characterRef
        else {
            return false
        }
        guard let target = gameSnapshot.characters[target] else {
            fatalError("Bad target reference \(target)")
        }
        if !readyableItem.isReady {
            return false
        }
        let usesMainHand = (character.mainHand == weapon.primaryKey)
        if usesMainHand && character.combatState!.handsUsed.contains(.mainHand) {
            return false
        }
        let usesOffHand = (character.offHand == weapon.primaryKey)
        if usesOffHand && character.combatState!.handsUsed.contains(.offHand) {
            return false
        }
        let availableRange =
            switch weapon.range {
            case .melee(let extraReach):
                character.reach + (extraReach ?? 0)
            case .ranged(short: _, long: let longDistance):
                longDistance
            }
        if !character.combatState!.space.expanded(by: availableRange).touchesOrOverlaps(
            target.combatState!.space
        ) {
            return false
        }
        return true
    }

    public func action(
        by characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation,
    ) async throws {
        let game = gameSession.game
        guard let character = game.anyCharacter(at: characterRef) else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard
            let readyableItem = character.equipment[weaponToStrikeWith],
            let weapon = readyableItem.core.core as? any WeaponSnapshot
        else {
            return
        }
        guard
            let targetCharacter = game.anyCharacter(at: target),
            target != RpgCharacterRef(of: character)
        else {
            return
        }
        // Run the damage test
        let weaponSkill = weapon.type.skill
        let targetPhysicalDefense = targetCharacter.defenses[.physical]
        let test = RpgAttackTest(
            tester: character.primaryKey,
            opponent: target,
            skill: weaponSkill,
            difficulty: targetPhysicalDefense,
            damageDice: weapon.damage.asArray,
            advantagesAvailable: 0,
            disadvantagesAvailable: 0,
            in: gameSession
        )
        if case .ranged(_, _) = weapon.range {
            let opponentsWhoCanReachMe = game.opponents(of: characterRef).filter {
                $0.combatState!.space.expanded(by: $0.reach).touchesOrOverlaps(
                    character.combatState!.space
                )
            }
            if !opponentsWhoCanReachMe.isEmpty {
                await game.broadcaster.tellAll(
                    DoubleTargetMessage(
                        w12:
                            "Because $1 is within $2's reach, $1 has to avoid giving the enemy an opening.",
                        wU2:
                            "Because you are within $2's reach, you have to avoid giving the enemy an opening.",
                        w1U:
                            "Because $1 is within your reach, $1 has to avoid giving you an opening.",
                        as1: characterRef,
                        as2: opponentsWhoCanReachMe[0].primaryKey,
                    )
                )
                test.disadvantagesAvailable += 1
            }
            let alliesNearTarget = game.characters.filter {
                $0.primaryKey != target
                    && $0.primaryKey != characterRef
                    && $0.combatState!.space.touchesOrOverlaps(targetCharacter.combatState!.space)
            }
            if alliesNearTarget.isEmpty {
                // TODO Raise the stakes and allow for a nearby target to be grazed on a complication.
            }
        }
        game.updateTest(test)
        await game.broadcaster.tellAll(
            DoubleTargetMessage(
                w12: "$1 targets $2 for a strike with their \(weaponToStrikeWith.name)",
                wU2: "You target $2 for a strike with your \(weaponToStrikeWith.name)",
                w1U: "$1 targets you for a strike with their \(weaponToStrikeWith.name)",
                as1: characterRef, as2: target))
        try await game.dispatch(TestEvent(StrikePhase.aboutToAttemptStrike, test: test))
        let result = try await test.roll(in: gameSession)
        let damageToDo: Int
        let verbOfStrike: (thirdPerson: Substring, secondPerson: Substring)
        if result.testResult {
            try await game.dispatch(TestEvent(TestHookType.afterSuccess, test: test))
            damageToDo = result.fullDamage
            verbOfStrike = ("strikes", "strike")
        } else {
            try await game.dispatch(TestEvent(TestHookType.afterFailure, test: test))
            if character.focus.value >= 1 {
                await game.broadcaster.tellHint(
                    "You can graze for \(result.grazeDamage). Focus: \(character.focus.value)/\(character.focus.maxValue)",
                    to: character.primaryKey)
                let shouldGraze =
                    try await character.brain.decide(
                        .shouldGraze, options: GrazeChoice.allCases, in: game.snapshot())
                    == .shouldGraze
                if shouldGraze {
                    character.focus.value -= 1
                    damageToDo = result.grazeDamage
                    verbOfStrike = ("grazes", "graze")
                } else {
                    damageToDo = 0
                    verbOfStrike = ("misses", "miss")
                }
            } else {
                damageToDo = 0
                verbOfStrike = ("misses", "miss")
            }
        }
        try await game.dispatch(TestEvent(StrikePhase.aboutToDealDamage, test: test))
        let damageDone: Damage
        if damageToDo > 0 {
            damageDone = await doDamage(
                Damage(damageToDo, type: weapon.damageType), to: targetCharacter.primaryKey)
            try await game.dispatch(TestEvent(StrikePhase.dealtDamage, test: test))
        } else {
            damageDone = Damage(0, type: .vital)
        }
        await game.broadcaster.tellAll(
            DoubleTargetMessage(
                w12:
                    "$1 \(verbOfStrike.thirdPerson) $2 and deals \(damageDone.amount) \(damageDone.type.rawValue) damage.",
                wU2:
                    "You \(verbOfStrike.secondPerson) $2 and deal \(damageDone.amount) \(damageDone.type.rawValue) damage.",
                w1U:
                    "$1 \(verbOfStrike.thirdPerson) you and deals \(damageDone.amount) \(damageDone.type.rawValue) damage.",
                as1: characterRef,
                as2: target
            )
        )
        if recordStrikeForThisHand {
            let wasMainHandUsed = (character.mainHand == weapon.primaryKey)
            let wasOffHandUsed = (character.offHand == weapon.primaryKey)
            if wasMainHandUsed {
                character.combatState?.handsUsed.insert(.mainHand)
            }
            if wasOffHandUsed {
                character.combatState?.handsUsed.insert(.offHand)
            }
        }
    }
}

extension Strike: CustomStringConvertible {
    public var description: String {
        "strike \(target.name) with \(weaponToStrikeWith.name)"
    }
}

public enum StrikePhase: Event {
    case aboutToAttemptStrike
    case aboutToDealDamage
    case dealtDamage
}

public enum GrazeChoice: Int, CaseIterable, Sendable {
    case shouldGraze = 0
    case shouldNotGraze = 1
}
extension GrazeChoice: CustomStringConvertible {
    public var description: String {
        switch self {
        case .shouldGraze: "graze for minimal damage"
        case .shouldNotGraze: "don't graze"
        }
    }
}

extension Strike {
    public static func possibleStrikes(
        for characterRef: RpgCharacterRef, in snapshot: GameSnapshot,
        target: RpgCharacterRef? = nil, weapon: ItemRef? = nil
    ) -> [Strike] {
        guard let character = snapshot.characters[characterRef] else {
            fatalError(
                "Can't calculate possibleStrikes for a character that doesn't exist.")
        }
        let targetCandidates: [RpgCharacterRef] =
            ({ (x: ()) in
                if let target {
                    return [target]
                }
                let characters = snapshot.characters
                let viableTargets = characters.filter {
                    $0.primaryKey != character.primaryKey && $0.health.value > 0
                }
                return viableTargets.map { $0.primaryKey }
            })(())
        let weaponCandidates: [ItemRef] =
            ({ (x: ()) in
                if let weapon {
                    return [weapon]
                }
                let equipment = character.equipment
                let viableWeapons = equipment.compactMap { x -> (any WeaponSnapshot)? in
                    guard x.isReady else {
                        return nil
                    }
                    return x.core.core as? any WeaponSnapshot
                }
                return viableWeapons.map { $0.primaryKey }
            })(())
        var possibleStrikes: [Strike] = []
        for target in targetCandidates {
            for weapon in weaponCandidates {
                let possibleStrike = Strike(target, with: weapon)
                if possibleStrike.canTakeAction(by: character.primaryKey, in: snapshot) {
                    possibleStrikes.append(possibleStrike)
                }
            }
        }
        return possibleStrikes
    }
}
