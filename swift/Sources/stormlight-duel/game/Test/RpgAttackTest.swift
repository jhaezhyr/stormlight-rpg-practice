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

    public func roll(in gameSession: isolated GameSession) async -> RpgAttackTestResult {
        let game = gameSession.game
        let character = game.anyCharacter(at: tester)!
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
                numberDie.roll(withModifier: $0.advantageNumber, rng: &game.rng)
            } else {
                nil
            }
        }

        //let testDieRollOpportunity = testDieRoll == 20
        //let testDieRollComplication = testDieRoll == 1
        // TODO Opportunities and complications

        let testModifier = character.modifiers[skill] ?? 0
        let testResult = testDieRoll + testModifier + otherModifiers >= difficulty

        return RpgAttackTestResult(
            testDieRoll: testDieRoll,
            testResult: testResult,
            advantagesApplied: advantagesApplied,
            disadvantagesApplied: disadvantagesApplied,
            opportunitiesApplied: 0,
            complicationsApplied: 0,
            damageDieRolls: damageDieRolls,
            damage: damageDieRolls.reduce(0, +) + damageModifiers
        )
    }
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
