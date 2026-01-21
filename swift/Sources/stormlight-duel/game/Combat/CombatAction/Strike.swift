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
        if !readyableItem.isReady {
            return false
        }
        // TODO check range
        return true
    }

    public func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession) async
    {
        let game = gameSession.game
        guard let character = game.characters[characterRef] else {
            fatalError("Bad character reference \(characterRef)")
        }
        guard
            let readyableItem = character.equipment[weaponToStrikeWith],
            let weapon = readyableItem.core as? any Weapon
        else {
            return
        }
        guard
            game.anyCharacter(at: target) != nil,
            target != RpgCharacterRef(of: character)
        else {
            return
        }
        let myCharacter: any RpgCharacter = game.anyCharacter(at: character.primaryKey)!
        let targetCharacter: any RpgCharacter = game.anyCharacter(at: target)!
        let meRef = RpgCharacterRef(of: character)
        // Run the damage test
        let weaponSkill = weapon.type.skill
        let targetPhysicalDefense = targetCharacter.defenses[.physical]
        let test = RpgSimpleTest(
            skill: weaponSkill, difficulty: targetPhysicalDefense, in: gameSession)
        let testRef = test.primaryKey
        game.updateTest(test)
        await game.naiveDispatch(
            StrikePhase.aboutToAttemptStrike, for: meRef, attempting: testRef, in: gameSession)
        await game.naiveDispatch(
            TestHookType.beforeRoll, for: meRef, attempting: testRef, in: gameSession)
        // TODO We're ignoring advantage, opportunity, etc. and just rolling
        let attackRoll = Int.random(in: 1...20, using: &game.rng)
        if attackRoll == 1 {
            test.complications += 1
        } else if attackRoll == 20 {
            test.opportunities += 1
        }
        let weaponModifier = character.modifiers[weaponSkill, default: 0]
        let attackNumber = attackRoll + weaponModifier
        test.testRolls.append(RpgTestRoll(numberDice: [.d20: attackRoll], plotDice: []))
        let damageDice = weapon.damage.dice
            .flatMap { die, count in
                Array(repeating: die, count: count)
                    .map { die in (die, Int.random(in: 1...die.rawValue, using: &game.rng)) }
            }
        let damageMinAmount = damageDice.reduce(0, { sum, die in sum + die.1 })
        let damageFullAmount = damageMinAmount + weaponModifier
        await game.naiveDispatch(
            TestHookType.beforeResolution, for: meRef, attempting: testRef, in: gameSession)
        await game.broadcaster.tell(
            "You rolled a \(attackRoll) (\(attackRoll)+\(weaponModifier)) with \(damageFullAmount) (\(damageMinAmount)+\(weaponModifier)) in damage dice",
            to: character.primaryKey)
        let success = (attackNumber >= test.difficulty)
        await game.broadcaster.tell(
            "The test to beat is \(test.difficulty) (\(targetCharacter.name)'s physical defense: \(targetPhysicalDefense))",
            to: character.primaryKey)
        test.success = success
        let damageToDo: Int
        let verbOfStrike: String
        if success {
            await game.broadcaster.tell(
                "You passed the test and hit!", to: character.primaryKey)
            await game.naiveDispatch(
                TestHookType.afterSuccess, for: meRef, attempting: testRef, in: gameSession)
            damageToDo = damageFullAmount
            verbOfStrike = "strikes"
        } else {
            await game.broadcaster.tell("You failed the attack test.", to: character.primaryKey)
            await game.naiveDispatch(
                TestHookType.afterFailure, for: meRef, attempting: testRef, in: gameSession)
            if character.focus.value >= 1 {
                await game.broadcaster.tell(
                    "You can graze for \(damageMinAmount). Focus: \(character.focus.value)/\(character.focus.maxValue)",
                    to: character.primaryKey)
                let shouldGraze =
                    await character.brain.decide(options: GrazeChoice.allCases, in: game.snapshot)
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
        await game.naiveDispatch(
            StrikePhase.aboutToDealDamage, for: meRef, attempting: testRef, in: gameSession)
        targetCharacter.takeDamage(Damage(damageToDo, type: weapon.damageType))
        await game.naiveDispatch(
            StrikePhase.dealtDamage, for: meRef, attempting: testRef, in: gameSession)
        await game.broadcaster.tellAll(
            "\(character.name) \(verbOfStrike) \(targetCharacter.name) and deals \(damageToDo) \(weapon.damageType.rawValue) damage."
        )
        // TODO Give lots of opportunities to resolve complications and opportunities, but those should all be spent by this point.
    }
}

public enum StrikePhase: HookTriggerForSomeRpgCharacterAndTest {
    case aboutToAttemptStrike
    case aboutToDealDamage
    case dealtDamage
}

public enum GrazeChoice: Int, CaseIterable, Sendable {
    case shouldGraze = 0
    case shouldNotGraze = 1
}
