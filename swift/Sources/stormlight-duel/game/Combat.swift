public struct Damage: Equatable, Hashable {
    public var amount: Int
    public var type: DamageType

    public init(_ amount: Int, realm: DamageType) {
        self.amount = amount
        self.type = realm
    }
}

public enum CombatPhase: HookTriggerForSomeRpgCharacter {
    case startOfTurn
    case endOfTurn
}

public enum TurnSpeed: Hashable, CaseIterable {
    case fast, slow

    var actionsPerTurn: Int {
        switch self {
        case .fast: 2
        case .slow: 3
        }
    }
}

public struct RpgCharacterCombatState {
    public var turnSpeed: TurnSpeed
    public var actionsRemaining: Int = 0
    public var weaponsUsed: Set<WeaponName> = []
    public var actionsTaken: Set<CombatActionName> = []
    public var reactionsRemaining: Int = 0
    public var hasStrikeAdvantageOver: Set<RpgCharacterRef> = []
}

public struct Combat {
    public init() {
    }

    public func run(in game: inout Game) {
        // Let everyone start the combat.
        for ref in game.characters.keys {
            let turnSpeed = game.characters[ref]!.brain.decide(options: TurnSpeed.allCases)
            game.characters[ref]!.combatState = RpgCharacterCombatState(
                turnSpeed: turnSpeed, reactionsRemaining: 1)
        }
        rounds: while true {
            // Give each character in this speed a turn
            speeds: for speed in TurnSpeed.allCases {
                // TODO allow characters to lower their speed mid-round somehow
                charactersThisTurn: for unmodifiedCharacter in game.characters.filter({ c in
                    c.combatState!.turnSpeed == speed
                }) {
                    let key = unmodifiedCharacter.primaryKey
                    var character: any RpgCharacter {
                        get { game.characters[key]!.core }
                        set { game.characters[key]!.core = newValue }
                    }
                    character.combatState!.reactionsRemaining = 1
                    character.combatState!.actionsRemaining =
                        character.combatState!.turnSpeed.actionsPerTurn
                    game.naiveDispatch(CombatPhase.startOfTurn, for: RpgCharacterRef(of: character))
                    actions: while true {
                        let choice = character.brain.decide(type: CombatChoice.self)
                        guard case .action(let action) = choice else {
                            continue actions
                        }
                        if character.combatState!.actionsRemaining >= action.actionCost
                            && character.focus.value >= action.focusCost
                            && action.canTakeAction(by: character, in: game)
                            && !character.combatState!.actionsTaken.contains(action.actionName)
                        {
                            character.focus.value -= action.focusCost
                            character.combatState!.actionsRemaining -= action.actionCost
                            action.action(by: character, in: &game)
                        }

                        if isOver(in: game) {
                            break rounds
                        }
                    }
                    game.naiveDispatch(CombatPhase.endOfTurn, for: RpgCharacterRef(of: character))
                }
            }
        }
    }

    public func isOver(in game: Game) -> Bool {
        !(game.characters.filter({ c in c.health.value > 0 }).count > 1)
    }
}

public enum CombatChoice {
    case action(any CombatAction)
    case endTurn
}

public typealias CombatActionName = String

public protocol CombatAction {
    var actionName: CombatActionName { get }
    var reactionCost: Int { get }
    var actionCost: Int { get }
    var focusCost: Int { get }
    func canTakeAction(by character: any RpgCharacter, in game: Game) -> Bool
    func action(by character: any RpgCharacter, in game: inout Game)
}
extension CombatAction {
    public func canTakeAction(by character: any RpgCharacter, in game: Game) -> Bool { true }
    public var focusCost: Int { 0 }
    public var reactionCost: Int { 0 }
    public var actionCost: Int { 0 }
    public var actionName: CombatActionName { "\(Self.self)" }
}

public struct Move: CombatAction {
    public var distanceToward: Distance
    public var actionCost: Int { 1 }
    public func action(by character: any RpgCharacter, in game: inout Game) {
        print("I moved")
    }

    public init(distanceToward: Distance) {
        self.distanceToward = distanceToward
    }
}

public struct Strike: CombatAction {
    public var actionCost: Int { 1 }
    public var weaponToStrikeWith: ItemRef
    public var target: RpgCharacterRef
    public func canTakeAction(by character: any RpgCharacter, in game: Game) -> Bool {
        guard
            let readyableItem = character.equipment[weaponToStrikeWith.name],
            readyableItem.core as? any Weapon != nil
        else {
            return false
        }
        guard
            game.anyCharacter(at: target) != nil,
            target != RpgCharacterRef(of: character)
        else {
            return false
        }
        // TODO check range
        return readyableItem.isReady
    }

    public func action(by character: any RpgCharacter, in game: inout Game) {
        guard
            let readyableItem = character.equipment[weaponToStrikeWith.name],
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
        var myCharacter: any RpgCharacter {
            get { game.anyCharacter(at: character.primaryKey)! }
            set { game.updateAnyCharacter(newValue) }
        }
        var targetCharacter: any RpgCharacter {
            get { game.anyCharacter(at: target)! }
            set { game.updateAnyCharacter(newValue) }
        }
        let meRef = RpgCharacterRef(of: character)
        // Run the damage test
        let weaponSkill = weapon.type.skill
        let targetPhysicalDefense = targetCharacter.defenses[.physical]
        let testRef = RpgTestRef.next()
        game.updateTest(RpgSimpleTest(skill: weaponSkill, difficulty: targetPhysicalDefense))
        game.naiveDispatch(StrikePhase.aboutToAttemptStrike, for: meRef, attempting: testRef)
        var test: RpgSimpleTest {
            get { game.test(at: testRef, as: RpgSimpleTest.self)! }
            set { game.updateTest(newValue) }
        }
        game.naiveDispatch(TestHookType.beforeRoll, for: meRef, attempting: testRef)
        // TODO We're ignoring advantage, opportunity, etc. and just rolling
        let attackRoll = Int.random(in: 1...20, using: &game.rng)
        if attackRoll == 1 {
            test.complications += 1
        } else if attackRoll == 20 {
            test.opportunities += 1
        }
        let attackNumber = attackRoll + (character.modifiers[weaponSkill, default: 0])
        test.testRolls.append(RpgTestRoll(numberDice: [.d20: attackRoll], plotDice: []))
        let damageDice = weapon.damage.dice
            .flatMap { die, count in
                Array(repeating: die, count: count)
                    .map { die in (die, Int.random(in: 1...die.rawValue, using: &game.rng)) }
            }
        let damageMinAmount = damageDice.reduce(0, { sum, die in sum + die.1 })
        let damageFullAmount = damageMinAmount + character.modifiers[weaponSkill, default: 0]
        game.naiveDispatch(TestHookType.beforeResolution, for: meRef, attempting: testRef)
        let success = (attackNumber >= test.difficulty)
        test.success = success
        let damageToDo: Int
        if success {
            game.naiveDispatch(TestHookType.afterSuccess, for: meRef, attempting: testRef)
            damageToDo = damageFullAmount
        } else {
            game.naiveDispatch(TestHookType.afterFailure, for: meRef, attempting: testRef)
            if character.focus.value >= 1 {
                let shouldGraze =
                    character.brain.decide(options: GrazeChoice.allCases) == .shouldGraze
                if shouldGraze {
                    myCharacter.focus.value -= 1
                    damageToDo = damageMinAmount
                } else {
                    damageToDo = 0
                }
            } else {
                damageToDo = 0
            }
        }
        game.naiveDispatch(StrikePhase.aboutToDealDamage, for: meRef, attempting: testRef)
        targetCharacter.takeDamage(Damage(damageToDo, realm: weapon.damageType))
        game.naiveDispatch(StrikePhase.dealtDamage, for: meRef, attempting: testRef)
        // TODO Give lots of opportunities to resolve complications and opportunities, but those should all be spent by this point.
    }
}

public enum StrikePhase: HookTriggerForSomeRpgCharacterAndTest {
    case aboutToAttemptStrike
    case aboutToDealDamage
    case dealtDamage
}

public enum GrazeChoice: Int, CaseIterable {
    case shouldGraze = 0
    case shouldNotGraze = 1
}

nonisolated(unsafe) public let allCombatActions: [CombatAction.Type] = [Strike.self, Move.self]
