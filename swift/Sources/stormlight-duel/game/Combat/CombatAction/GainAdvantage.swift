public struct GainAdvantage: CombatAction {
    public static let actionCost: Int = 1

    public let opponent: RpgCharacterRef
    public let chosenSkill: CoreSkillName

    public init(opponent: RpgCharacterRef, skill chosenSkill: CoreSkillName) {
        self.opponent = opponent
        self.chosenSkill = chosenSkill
    }

    public func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession) async
    {
        guard
            let (me: me, opponent: opponent, game: game) = try? resolveReferences(me: characterRef)
        else {
            return
        }
        let opponentDefense = opponent.defenses[chosenSkill.realm]

        let test = RpgSimpleTest(
            tester: me.primaryKey,
            opponent: opponent.primaryKey,
            skill: .core(chosenSkill),
            difficulty: opponentDefense,
            in: gameSession
        )
        game.updateTest(test)
        let result = await test.roll(in: gameSession)
        if result.testResult {
            me.conditions.upsert(
                AnyCondition(
                    HasGainedAdvantageCondition(
                        skill: chosenSkill,
                        for: me.primaryKey,
                        against: opponent.primaryKey,
                    )
                )
            )
        } else {
            await game.broadcaster.tell("You failed to gain advantage.", to: me.primaryKey)
            await game.broadcaster.tell(
                "\(me.primaryKey.name) failed to gain advantage over you.", to: opponent.primaryKey)
        }
        await game.naiveDispatch(
            result.testResult ? TestHookType.afterSuccess : TestHookType.afterFailure,
            for: me.primaryKey,
            attempting: test.primaryKey,
            in: gameSession
        )
        game.removeTest(test)
    }

    public func resolveReferences(
        me: RpgCharacterRef, in gameSession: isolated GameSession = #isolation
    ) throws -> (
        me: any RpgCharacter,
        opponent: any RpgCharacter,
        game: Game,
    ) {
        guard let me = gameSession.game.anyCharacter(at: me),
            let opponent = gameSession.game.anyCharacter(at: opponent)
        else {
            throw CancellationError()
        }
        return (me: me, opponent: opponent, game: gameSession.game)
    }
}
extension GainAdvantage: CustomStringConvertible {
    public var description: String {
        "gain advantage over \(opponent.name) using \(chosenSkill)"
    }
}

public struct HasGainedAdvantageCondition: LeafCondition, ConditionSnapshot {
    public let id: Int
    public var snapshot: any ConditionSnapshot { self }
    /// The skill with which we gained advantage. This is the skill we cannot use during the attack test.
    public let skill: CoreSkillName
    public let characterRef: RpgCharacterRef
    public let opponentRef: RpgCharacterRef

    public let selfListenersSelfHooksForTests: [any SelfListenerSelfHookForTestProtocol]

    public init(
        skill: CoreSkillName,
        for characterRef: RpgCharacterRef,
        against opponentRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        let id = gameSession.nextId()
        self.id = id
        self.skill = skill
        self.characterRef = characterRef
        self.opponentRef = opponentRef
        self.selfListenersSelfHooksForTests = [
            gameSession.selfListen(
                toMyTests: TestHookType.beforeRoll,
                as: AnyRpgCharacter.self,
                testType: AnyRpgTest.self,
            ) { game, character, test in
                guard characterRef == test.tester else {
                    await game.game.broadcaster.tell(
                        "Can't gain advantage unless it's my test.", to: characterRef)
                    return
                }
                guard let test = test.core as? RpgAttackTest else {
                    await game.game.broadcaster.tell(
                        "Can't gain advantage except on attack tests", to: characterRef)
                    return
                }
                guard opponentRef == test.opponent else {
                    await game.game.broadcaster.tell(
                        "Can't gain advantage against a different opponent", to: characterRef)
                    return
                }
                if test.skill == .core(skill) {
                    await game.game.broadcaster.tell(
                        "Can't use advantage gained with the same skill we're using to strike.",
                        to: characterRef)
                    return
                    // TODO Does the advantage stick around?
                }
                await game.game.broadcaster.tell(
                    "You have an advantage for this attack!", to: characterRef)

                test.advantagesAvailable += 1

                character.core.conditions.remove(id)
            }
        ]
    }
}
extension HasGainedAdvantageCondition: CustomStringConvertible {
    public var description: String {
        "gained advantage over \(opponentRef.name) with \(skill)"
    }
}
