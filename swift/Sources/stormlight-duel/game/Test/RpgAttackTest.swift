public class RpgAttackTest: RpgTest {
    public var id: Int

    public var tester: RpgCharacterRef
    public var opponent: RpgCharacterRef?

    public var skill: SkillName
    public var otherModifiers: Int = 0
    public var difficulty: Int  // In a head to head, this is the opponent's total number.

    public var damageDice: [NumberDie]
    public var damageModifiers: Int = 0

    public var advantagesAvailable: Int = 0
    public var disadvantagesAvailable: Int = 0
    public var opportunitiesAvailable: Int = 0
    public var complicationsAvailable: Int = 0

    public init(
        tester: RpgCharacterRef,
        opponent: RpgCharacterRef? = nil,
        skill: SkillName,
        otherModifiers: Int? = nil,
        difficulty: Int,
        damageDice: [NumberDie],
        damageModifiers: Int? = 0,
        advantagesAvailable: Int? = nil,
        disadvantagesAvailable: Int? = nil,
        opportunitiesAvailable: Int? = nil,
        complicationsAvailable: Int? = nil,
        in gameSession: isolated GameSession
    ) {
        self.id = gameSession.nextId()
        self.tester = tester
        if let opponent { self.opponent = opponent }
        self.skill = skill
        self.difficulty = difficulty
        if let otherModifiers { self.otherModifiers = otherModifiers }
        self.damageDice = damageDice
        if let damageModifiers { self.damageModifiers = damageModifiers }
        if let advantagesAvailable { self.advantagesAvailable = advantagesAvailable }
        if let disadvantagesAvailable { self.disadvantagesAvailable = disadvantagesAvailable }
        if let opportunitiesAvailable { self.opportunitiesAvailable = opportunitiesAvailable }
        if let complicationsAvailable { self.complicationsAvailable = complicationsAvailable }
    }

    public var snapshot: any RpgTestSnapshot {
        RpgAttackTestSnapshot(
            id: id, skill: skill, otherModifiers: otherModifiers, difficulty: difficulty,
            tester: tester, opponent: opponent,
            advantagesAvailable: advantagesAvailable,
            disadvantagesAvailable: disadvantagesAvailable,
            opportunitiesAvailable: opportunitiesAvailable,
            complicationsAvailable: complicationsAvailable)
    }

    /// Remember to call .afterSuccess or .afterFailure after calling this
    public func roll(in gameSession: isolated GameSession) async -> RpgAttackTestResult {
        let game = gameSession.game
        let character = game.anyCharacter(at: tester)!
        await game.dispatch(TestEvent(TestHookType.beforeRoll, test: self))
        let (
            advantagesApplied,
            disadvantagesApplied,
            dieRoleCounts
        ) = await assignAdvantagesAndDisadvantages(
            advantagesAvailable: advantagesAvailable,
            disadvantagesAvailable: disadvantagesAvailable,
            disadvantageBrain: opponent.map { game.anyCharacter(at: $0)!.brain }
                ?? game.gameMasterBrain,
            advantageBrain: character.brain,
            dieRoleCounts: .init(
                [AttackDieRole.testDie] + damageDice.map(AttackDieRole.damageDie(die:)))
        )
        let testDieRoll = dieRoleCounts.filter { $0.role == .testDie }.map {
            NumberDie.d20.roll(
                withModifier: $0.advantageNumber, rng: &game.rng)
        }[0]
        let damageDieRolls = dieRoleCounts.compactMap {
            if case .damageDie(let numberDie) = $0.role {
                (
                    die: numberDie, modifier: $0.advantageNumber,
                    result: numberDie.roll(withModifier: $0.advantageNumber, rng: &game.rng)
                )
            } else {
                nil
            }
        }

        await game.dispatch(TestEvent(TestHookType.beforeResolution, test: self))

        //let testDieRollOpportunity = testDieRoll == 20
        //let testDieRollComplication = testDieRoll == 1
        // TODO Opportunities and complications

        let testModifier = character.modifiers[skill] ?? 0
        let testResult = testDieRoll + testModifier + otherModifiers >= difficulty

        let modifierBit =
            if let modifier = dieRoleCounts.first(where: { roleWithAdvantageNumber in
                roleWithAdvantageNumber.role == .testDie
            })!.advantageNumber {
                " with \(modifier)"
            } else {
                ""
            }
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                "$1 rolled a \(NumberDie.d20)\(modifierBit) and got a \(testDieRoll). The skill was \(skill), so their modifier was \(testModifier). The difficulty was \(difficulty) and they got \(testDieRoll + testModifier). \(testResult ? "$1 hit!" : "$1 failed the attack test.")",
                "You rolled a \(NumberDie.d20)\(modifierBit) and got a \(testDieRoll). The skill was \(skill), so your modifier was \(testModifier). The difficulty was \(difficulty) and you got \(testDieRoll + testModifier). \(testResult ? "You hit!" : "You failed the attack test.")",
                for: tester)
        )

        let (dice:dice, result:result) = describeDice(damageDieRolls)
        let modifiers = dieRoleCounts.compactMap {
            if case .damageDie(_) = $0.role {
                $0.advantageNumber
            } else {
                nil
            }
        }
        let damageModifierBit =
            switch (modifiers.count { $0 == .advantage }, modifiers.count { $0 == .disadvantage }) {
            case (0, 0): ""
            case (1, 0): " with advantage"
            case (let x, 0): " with \(x) advantages"
            case (0, 1): " with disadvantage"
            case (0, let x): " with \(x) disadvantages"
            case (1, 1): " with 1 advantage and 1 disadvantage"
            case (let x, 1): " with \(x) advantage and 1 disadvantage"
            case (let x, let y): " with \(x) advantages and \(y) disadvantages"
            }
        await gameSession.game.broadcaster.tellAll(
            SingleTargetMessage(
                "$1 rolled \(dice)\(damageModifierBit) for their damage and got \(result).",
                "You rolled \(dice)\(damageModifierBit) for your damage and got \(result).",
                for: tester))

        let dieRollResults = damageDieRolls.map { $0.result }
        return RpgAttackTestResult(
            testDieRoll: testDieRoll,
            testResult: testResult,
            advantagesApplied: advantagesApplied,
            disadvantagesApplied: disadvantagesApplied,
            opportunitiesApplied: 0,
            complicationsApplied: 0,
            damageDieRolls: dieRollResults,
            damage: dieRollResults.reduce(0, +) + damageModifiers
        )
    }
}

public func describeDice(_ dice: [(die: NumberDie, modifier: RollModifier?, result: Int)]) -> (
    dice: String, result: String
) {
    // You rolled a d10 with advantage and got an 8.
    // You rolled two d10s and got 2 and 3.
    // You rolled a d10 with advantage and a d8 and got 4+1.
    // You rolled four d6s and a d6 with disadvantage and got 6+5+4+3+2
    // You rolled two d4s with advantage and got 2+3

    // Bucket them by role.
    struct DieAndModifier: Hashable {
        var die: NumberDie
        var modifier: RollModifier?
    }
    var buckets: [DieAndModifier: [Int]] = [:]
    for (die, modifier, result) in dice {
        buckets[DieAndModifier(die: die, modifier: modifier), default: []].append(result)
    }
    let sortedBuckets = buckets.sorted { lh, rh in lh.key.die.rawValue > rh.key.die.rawValue }
    let spelledOutNumbers = [
        0: "no",
        1: "a",
        2: "two",
        3: "three",
        4: "four",
        5: "five",
        6: "six",
        7: "seven",
        8: "eight",
        9: "nine",
        10: "ten",
    ]
    let bucketDiceDescriptions = sortedBuckets.map { (dieAndModifer, results) in
        "\(spelledOutNumbers[results.count] ?? "lots of") \(dieAndModifer.die)\(results.count > 1 ? "s" : "")"
    }
    let bucketDiceDescriptionWhole =
        switch bucketDiceDescriptions.count {
        case 0:
            "nothing"
        case 1:
            bucketDiceDescriptions[0]
        case 2:
            bucketDiceDescriptions.joined(separator: " and ")
        default:
            bucketDiceDescriptions.dropLast().joined(separator: ", ") + ", and "
                + bucketDiceDescriptions.last!
        }
    let resultDescription = sortedBuckets.flatMap { $0.value }.map { "\($0)" }.joined(
        separator: "+")
    return (dice: bucketDiceDescriptionWhole, result: resultDescription)
}

public enum AttackDieRole: Sendable, Equatable, Hashable {
    case testDie
    case damageDie(die: NumberDie)
}
extension AttackDieRole: Comparable {
    public static func < (lhs: AttackDieRole, rhs: AttackDieRole) -> Bool {
        switch (lhs, rhs) {
        case (.testDie, .testDie):
            return false
        case (.testDie, .damageDie(die: _)):
            return true
        case (.damageDie(die: _), .testDie):
            return false
        case (.damageDie(let lh), .damageDie(let rh)):
            return lh.rawValue > rh.rawValue
        }
    }
}

extension AttackDieRole: CustomStringConvertible {
    public var description: String {
        switch self {
        case .damageDie(let die):
            "\(die) (damage die)"
        case .testDie:
            "\(NumberDie.d20) (test die)"
        }
    }
}

public struct RpgAttackTestResult: RpgTestResultProtocol {
    public let testDieRoll: Int
    public let testResult: Bool

    public let advantagesApplied: Int
    public let disadvantagesApplied: Int
    public let opportunitiesApplied: Int
    public let complicationsApplied: Int

    public let damageDieRolls: [Int]
    public let damage: Int
}

public typealias RpgAttackTestSnapshot = RpgSimpleTestSnapshot
