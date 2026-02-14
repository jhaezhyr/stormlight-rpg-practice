public struct Strike: CombatAction {
    public static var actionCost: Int { 1 }
    public var weaponToStrikeWith: ItemRef
    public var target: RpgCharacterRef

    public init(_ target: RpgCharacterRef, with weaponToStrikeWith: ItemRef) {
        self.target = target
        self.weaponToStrikeWith = weaponToStrikeWith
    }

    public func canTakeAction(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Bool
    {
        guard let character = gameSnapshot.characters[characterRef] else {
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
        if character.combatState!.weaponsUsed.contains(weapon.weaponName) {
            return false
        }
        if !canAffordAction(by: characterRef, in: gameSnapshot) {
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
        guard let character = game.characters[characterRef] else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard
            let readyableItem = character.equipment[weaponToStrikeWith],
            let weapon = readyableItem.core.core as? any WeaponSnapshot
        else {
            return
        }
        guard
            game.anyCharacter(at: target) != nil,
            target != RpgCharacterRef(of: character)
        else {
            return
        }
        // TODO Do things for ranged weapons.
        let myCharacter: any RpgCharacter = game.anyCharacter(at: character.primaryKey)!
        let targetCharacter: any RpgCharacter = game.anyCharacter(at: target)!
        // Run the damage test
        let weaponSkill = weapon.type.skill
        let targetPhysicalDefense = targetCharacter.defenses[.physical]
        let test = RpgAttackTest(
            tester: character.primaryKey,
            opponent: target,
            skill: weaponSkill,
            difficulty: targetPhysicalDefense,
            damageDice: weapon.damage.asArray,
            damageModifiers: 0,
            advantagesAvailable: 0,
            disadvantagesAvailable: 0,
            in: gameSession
        )
        game.updateTest(test)
        await game.broadcaster.tellAll(
            DoubleTargetMessage(
                w12: "$1 targets $2 for a strike with their \(weaponToStrikeWith.name)",
                wU2: "You target $2 for a strike with your \(weaponToStrikeWith.name)",
                w1U: "$1 targets you for a strike with your \(weaponToStrikeWith.name)",
                as1: characterRef, as2: target))
        try await game.dispatch(TestEvent(StrikePhase.aboutToAttemptStrike, test: test))
        let result = try await test.roll(in: gameSession)
        let weaponModifier = character.modifiers[weaponSkill, default: 0]
        let damageMinAmount = result.damage
        let damageFullAmount = result.damage + weaponModifier
        try await game.dispatch(TestEvent(TestHookType.beforeResolution, test: test))
        let damageToDo: Int
        let verbOfStrike: (thirdPerson: Substring, secondPerson: Substring)
        if result.testResult {
            try await game.dispatch(TestEvent(TestHookType.afterSuccess, test: test))
            damageToDo = damageFullAmount
            verbOfStrike = ("strikes", "strike")
        } else {
            try await game.dispatch(TestEvent(TestHookType.afterFailure, test: test))
            if character.focus.value >= 1 {
                await game.broadcaster.tellHint(
                    "You can graze for \(damageMinAmount). Focus: \(character.focus.value)/\(character.focus.maxValue)",
                    to: character.primaryKey)
                let shouldGraze =
                    try await character.brain.decide(
                        .shouldGraze, options: GrazeChoice.allCases, in: game.snapshot)
                    == .shouldGraze
                if shouldGraze {
                    myCharacter.focus.value -= 1
                    damageToDo = damageMinAmount
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
        targetCharacter.takeDamage(Damage(damageToDo, type: weapon.damageType))
        try await game.dispatch(TestEvent(StrikePhase.dealtDamage, test: test))
        await game.broadcaster.tellAll(
            DoubleTargetMessage(
                w12:
                    "$1 \(verbOfStrike.thirdPerson) $2 and deals \(damageToDo) \(weapon.damageType.rawValue) damage.",
                wU2:
                    "You \(verbOfStrike.secondPerson) $2 and deal \(damageToDo) \(weapon.damageType.rawValue) damage.",
                w1U:
                    "$1 \(verbOfStrike.thirdPerson) you and deals \(damageToDo) \(weapon.damageType.rawValue) damage.",
                as1: characterRef, as2: target)
        )
        character.combatState?.weaponsUsed.insert(weapon.weaponName)
        // TODO Give lots of opportunities to resolve complications and opportunities, but those should all be spent by this point.
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
