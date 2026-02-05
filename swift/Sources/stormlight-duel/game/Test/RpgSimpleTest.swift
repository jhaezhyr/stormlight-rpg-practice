public class RpgSimpleTest: RpgTest {
    public var id: Int

    public var tester: RpgCharacterRef
    public var opponent: RpgCharacterRef?

    public var skill: SkillName
    public var otherModifiers: Int = 0
    public var difficulty: Int  // In a head to head, this is the opponent's total number.

    public var advantagesAvailable: Int = 0
    public var disadvantagesAvailable: Int = 0
    public var opportunitiesAvailable: Int = 0
    public var complicationsAvailable: Int = 0

    public init(
        tester: RpgCharacterRef,
        opponent: RpgCharacterRef? = nil,
        skill: SkillName,
        difficulty: Int,  // In a head to head, this is the opponent's total number.
        otherModifiers: Int? = nil,
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
        if let advantagesAvailable { self.advantagesAvailable = advantagesAvailable }
        if let disadvantagesAvailable { self.disadvantagesAvailable = disadvantagesAvailable }
        if let opportunitiesAvailable { self.opportunitiesAvailable = opportunitiesAvailable }
        if let complicationsAvailable { self.complicationsAvailable = complicationsAvailable }
    }

    public var snapshot: any RpgTestSnapshot {
        RpgSimpleTestSnapshot(
            id: id, skill: skill, otherModifiers: otherModifiers, difficulty: difficulty,
            tester: tester, opponent: opponent,
            advantagesAvailable: advantagesAvailable,
            disadvantagesAvailable: disadvantagesAvailable,
            opportunitiesAvailable: opportunitiesAvailable,
            complicationsAvailable: complicationsAvailable)
    }

    /// Make sure to dispatch an "afterSuccess" or "afterFailure"
    public func roll(in gameSession: isolated GameSession) async -> RpgSimpleTestResult {
        let game = gameSession.game
        let character = game.anyCharacter(at: tester)!
        await game.naiveDispatch(
            TestHookType.beforeRoll,
            for: tester,
            attempting: primaryKey,
            in: gameSession
        )
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
            dieRoleCounts: [SimpleTestDieRole.testDie]
        )
        let testDieRollModifier = dieRoleCounts.first { _ in true }!.advantageNumber
        let testDieRoll = NumberDie.d20.roll(
            withModifier: testDieRollModifier,
            rng: &game.rng
        )

        await game.naiveDispatch(
            TestHookType.beforeResolution,
            for: tester,
            attempting: primaryKey,
            in: gameSession
        )

        //let testDieRollOpportunity = testDieRoll == 20
        //let testDieRollComplication = testDieRoll == 1
        // TODO Opportunities and complications

        let testModifier = character.modifiers[skill] ?? 0
        let testResult = testDieRoll + testModifier >= difficulty

        let modifierBit =
            if let modifier = dieRoleCounts.first(where: { _ in true })!.advantageNumber {
                " with \(modifier)"
            } else {
                ""
            }
        await gameSession.game.broadcaster.tell(
            "You rolled a \(NumberDie.d20)\(modifierBit) and got a \(testDieRoll). The skill was \(skill), so your modifier was \(testModifier). The difficulty was \(difficulty) and you got \(testDieRoll + testModifier). \(testResult ? "You passed!" : "You failed.")",
            to: character.primaryKey
        )

        return RpgSimpleTestResult(
            testDieRoll: testDieRoll,
            testResult: testResult,
            advantagesApplied: advantagesApplied,
            disadvantagesApplied: disadvantagesApplied,
            opportunitiesApplied: 0,
            complicationsApplied: 0
        )
    }
}

public enum SimpleTestDieRole: Sendable, Hashable {
    case testDie
}
extension SimpleTestDieRole: Comparable {
}

public struct RpgSimpleTestResult: RpgTestResultProtocol {
    public let testDieRoll: Int
    public let testResult: Bool

    public let advantagesApplied: Int
    public let disadvantagesApplied: Int
    public let opportunitiesApplied: Int
    public let complicationsApplied: Int
}

public struct RpgSimpleTestSnapshot: RpgTestSnapshot {
    public let id: Int
    public var skill: SkillName
    public var otherModifiers: Int
    public var difficulty: Int

    public var tester: RpgCharacterRef
    public var opponent: RpgCharacterRef?

    public var advantagesAvailable: Int
    public var disadvantagesAvailable: Int
    public var opportunitiesAvailable: Int
    public var complicationsAvailable: Int
}
