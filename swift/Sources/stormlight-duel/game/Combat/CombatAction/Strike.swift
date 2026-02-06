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
    ) async {
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
        await game.dispatch(TestEvent(StrikePhase.aboutToAttemptStrike, test: test))
        let result = await test.roll(in: gameSession)
        let weaponModifier = character.modifiers[weaponSkill, default: 0]
        let damageMinAmount = result.damage
        let damageFullAmount = result.damage + weaponModifier
        await game.dispatch(TestEvent(TestHookType.beforeResolution, test: test))
        let damageToDo: Int
        let verbOfStrike: String
        if result.testResult {
            await game.dispatch(TestEvent(TestHookType.afterSuccess, test: test))
            damageToDo = damageFullAmount
            verbOfStrike = "strikes"
        } else {
            await game.dispatch(TestEvent(TestHookType.afterFailure, test: test))
            if character.focus.value >= 1 {
                await game.broadcaster.tell(
                    "You can graze for \(damageMinAmount). Focus: \(character.focus.value)/\(character.focus.maxValue)",
                    to: character.primaryKey)
                let shouldGraze =
                    await character.brain.decide(
                        .shouldGraze, options: GrazeChoice.allCases, in: game.snapshot)
                    == .shouldGraze
                if shouldGraze {
                    myCharacter.focus.value -= 1
                    damageToDo = damageMinAmount
                    verbOfStrike = "grazes"
                } else {
                    damageToDo = 0
                    verbOfStrike = "misses"
                }
            } else {
                damageToDo = 0
                verbOfStrike = "misses"
            }
        }
        await game.dispatch(TestEvent(StrikePhase.aboutToDealDamage, test: test))
        targetCharacter.takeDamage(Damage(damageToDo, type: weapon.damageType))
        await game.dispatch(TestEvent(StrikePhase.dealtDamage, test: test))
        await game.broadcaster.tellAll(
            "\(character.name) \(verbOfStrike) \(targetCharacter.name) and deals \(damageToDo) \(weapon.damageType.rawValue) damage."
        )
        character.combatState?.weaponsUsed.insert(weapon.weaponName)
        // TODO Give lots of opportunities to resolve complications and opportunities, but those should all be spent by this point.
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
