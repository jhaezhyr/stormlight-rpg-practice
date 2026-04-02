import CompleteDictionary
import KeyedSet

extension PrefabCharacters {
    @discardableResult
    public static func archer(
        ref: RpgCharacterRef? = nil,
        homeCulture: CultureName = .alethi,
        isPlayer: Bool,
        brain: RpgCharacterBrain,
        andAddTo gameSession: isolated GameSession = #isolation
    ) -> PlayerRpgCharacter {
        let ref = ref ?? RpgCharacterRef(name: "Archer")
        return PlayerRpgCharacter(
            name: ref.name, expertises: [.weapon(.knife), .weapon(.longbow)],
            equipment: [
                .init(BasicArmorTypes.leather(), isReady: true),
                .init(basicWeapons[.knife]!(gameSession), isReady: false),
                .init(basicWeapons[.longbow]!(gameSession), isReady: true),
            ],
            attributes: [
                .strength: 2, .speed: 1, .intellect: 2, .willpower: 1, .awareness: 2, .presence: 1,
            ],
            ranksInCoreSkills: [
                .agility: 2,
                .heavyWeaponry: 2,
                .lightWeaponry: 2,
                .discipline: 2,
                .perception: 2,
                .survival: 2,
            ].complete { _ in 0 },
            ranksInOtherSkills: [:],
            health: Resource(maxValue: Int.random(in: 9...15, using: &gameSession.game.rng)),
            focus: Resource(maxValue: 3),
            investiture: Resource(maxValue: 0), reach: 0,
            features: [
                .init(TakeAimActionFeature()),
                .init(ImmobilizingShotReactionFeature(for: ref)),
            ],
            conditions: [], brain: brain, isPlayer: isPlayer, andAddTo: gameSession)
    }
}

public struct TakeAimActionFeature: CharacterFeature, CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { "Take Aim action" }
    public var actionsProvided: [any CombatAction] {
        [TakeAimAction(opponent: nil, skill: nil)]
    }
}

public struct ImmobilizingShotReactionFeature: CharacterFeature {
    public var name: CharacterFeatureRef { "Immobilizing Shot reaction" }
    public let handlers: [any EventHandlerProtocol]
    public init(for characterRef: RpgCharacterRef) {
        self.handlers = [
            EventHandler<MovementStepEvent> {
                event, gameSession in
                guard event.subject.primaryKey != characterRef else {
                    return
                }
                guard let character = gameSession.game.anyCharacter(at: characterRef) else {
                    return
                }
                guard
                    let longbow = character.equipment.compactMap({ readyable in
                        if let weapon = readyable.core.core as? any Weapon,
                            weapon.weaponName == .longbow
                        {
                            weapon
                        } else {
                            nil
                        }
                    }).first
                else {
                    return
                }
                let longbowRef = longbow.primaryKey
                // TODO Can sense the moving subject
                guard character.combatState!.reactionsRemaining >= 1 && character.focus.value >= 1
                else {
                    return
                }
                let reactionDecision = try await character.brain.decide(
                    .shouldShootImmobilizingShot,
                    iterableType: ImmobilizingShotReactionDecision.self,
                    in: gameSession.game.snapshot())
                guard reactionDecision == .shouldShootImmobilizingShot else {
                    return
                }
                character.focus.value -= 1
                character.combatState!.reactionsRemaining -= 1

                let subjectRef = event.subject.primaryKey
                try await withTempHandlers([
                    EventHandler<TestEvent<TestHookType>> {
                        event, gameSession in
                        // TODO Don't let this latch onto any other test than the test that this strike will provide.
                        // Maybe passing the potential attack test id into the action could be useful.
                        guard event.event == .afterSuccess else {
                            return
                        }
                        guard var opponent = event.opponent else {
                            return
                        }
                        await gameSession.game.broadcaster.tellAll(
                            DoubleTargetMessage(
                                w12:
                                    "$1's shot immobilized $2! They won't be able to move until the end of $1's next turn.",
                                wU2:
                                    "Your shot immobilized $2! They won't be able to move until the end of your next turn.",
                                w1U:
                                    "$1's shot immobilized you! You won't be able to move until the end of $1's next turn.",
                                as1: characterRef,
                                as2: opponent.primaryKey
                            )
                        )
                        let condition = DurationCondition(
                            core: Immobilized(),
                            duration: 1,
                            turnsFor: characterRef,
                            butBelongingTo: opponent.primaryKey
                        )
                        opponent.conditions.upsert(.init(condition))
                    }
                ]) { gameSession in
                    try await Strike(subjectRef, with: longbowRef, recordStrikeForThisHand: false)
                        .action(
                            by: characterRef
                        )
                }
            }
        ]
    }

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any CharacterFeatureSnapshot
    {
        DummyCharacterFeatureSnapshot(name: name, actionsProvided: actionsProvided)
    }
}

public enum ImmobilizingShotReactionDecision: String, CaseIterable, Sendable, Hashable {
    case shouldShootImmobilizingShot = "shoot an immobilizing shot"
    case shouldNotShootImmobilizingShot = "don't shoot an immobilizing shot"
}

public struct TakeAimAction: CombatAction {
    public static func actionCost(by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot)
        -> Int
    {
        0
    }
    public var opponent: RpgCharacterRef?
    public var skill: CoreSkillName?
    public init(opponent: RpgCharacterRef?, skill: CoreSkillName?) {
        self.opponent = opponent
        self.skill = skill
    }
    public static func canMaybeTakeAction(
        by characterRef: RpgCharacterRef, in gameSnapshot: GameSnapshot
    )
        -> Bool
    {
        guard let character = gameSnapshot.characters[characterRef] else {
            return false
        }
        guard !character.conditions.contains(where: { $0.type == Surprised.type }) else {
            return false
        }
        guard character.combatState!.turnsTaken == 0 else {
            return false
        }
        return InteractiveGainAdvantage.canMaybeTakeAction(by: characterRef, in: gameSnapshot)
    }
    public func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession)
        async throws
    {
        try await InteractiveGainAdvantage(opponent: opponent, chosenSkill: skill).action(
            by: characterRef, in: gameSession)
    }
}
