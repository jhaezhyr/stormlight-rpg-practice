import CompleteDictionary
import KeyedSet

extension PrefabCharacters {
    public static func spearInfantry(
        ref: RpgCharacterRef? = nil,
        homeCulture: CultureName = .alethi,
        isPlayer: Bool,
        brain: RpgCharacterBrain,
        in gameSession: isolated GameSession = #isolation
    ) -> PlayerRpgCharacter {
        let ref = ref ?? RpgCharacterRef(name: "Spear Infantry")
        return PlayerRpgCharacter(
            name: ref.name,
            expertises: [
                .weapon(.shortspear),
                .weapon(.javelin),
                .culture(homeCulture),
            ],
            equipment: [
                .init(BasicArmorTypes.chain(), isReady: true),
                .init(basicWeapons[.shortspear]!(gameSession), isReady: true),
                .init(basicWeapons[.shortbow]!(gameSession), isReady: true),
                .init(basicWeapons[.shield]!(gameSession), isReady: true),
            ],
            attributes: [
                .strength: 2,
                .speed: 2,
                .intellect: 1,
                .willpower: 1,
                .awareness: 2,
                .presence: 1,
            ],
            ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int> {
                skill in
                switch skill {
                case .athletics: 2
                case .heavyWeaponry: 2
                case .lightWeaponry: 2
                case .discipline: 1
                case .intimidation: 2
                case .perception: 3
                default: 0
                }
            },
            ranksInOtherSkills: [:],
            health: Resource(maxValue: Int.random(in: 11...17, using: &gameSession.game.rng)),
            focus: Resource(maxValue: 3),
            investiture: Resource(maxValue: 0),
            reach: 0,
            features: [
                .init(MinionFeature(for: ref)),
                .init(MartialDrillFeature(for: ref)),
                .init(MilitaryTacticsFeature(for: ref)),
                .init(ShieldBashActionFeature(for: ref)),
            ],
            conditions: [],
            brain: brain,
            isPlayer: isPlayer,
        )
    }
}

public struct MartialDrillFeature: CharacterFeature {
    public var name: CharacterFeatureRef { "Martial Drill" }

    public let handlers: [any EventHandlerProtocol]

    public func _snapshot(in gameSession: isolated GameSession) -> any CharacterFeatureSnapshot {
        DummyCharacterFeatureSnapshot(name: name)
    }

    public init(
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.handlers = [
            EventHandler<SceneStartEvent> {
                event, gameSession in
                guard var character = gameSession.game.anyCharacter(at: characterRef) else {
                    return
                }

                guard
                    character.equipment.contains(where: { readyable in
                        readyable.isReady
                            && (readyable.core.trueSelf as? any Weapon)?.weaponName == .shield
                    })
                else {
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1:
                                "$1 has no shield and cannot be part of military drill formation.",
                            wU:
                                "You have no shield and cannot be part of your military drill formation.",
                            as1: characterRef
                        )
                    )
                    return
                }

                guard !character.conditions.contains(where: { $0.type == Surprised.type }) else {
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1:
                                "$1 is too surpsied to be part of their military drill formation.",
                            wU:
                                "You are too surpsied to be part of your military drill formation.",
                            as1: characterRef
                        )
                    )
                    return
                }

                await gameSession.game.broadcaster.tellAll(
                    SingleTargetMessage(
                        w1:
                            "$1 takes a defensive stance, ready to brace against incoming attacks.",
                        wU:
                            "You take a defensive stance, ready to brace against incoming attacks.",
                        as1: characterRef
                    )
                )
                character.conditions.upsert(.init(BraceCondition(for: characterRef)))
            }
        ]
    }
}

public struct MilitaryTacticsFeature: CharacterFeature {
    public var name: CharacterFeatureRef { "Military Tactics" }
    public let handlers: [any EventHandlerProtocol]
    public func _snapshot(in gameSession: isolated GameSession) -> any CharacterFeatureSnapshot {
        DummyCharacterFeatureSnapshot(name: name)
    }
    public init(
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.handlers = [
            EventHandler<ReactionCalculation<ReactiveStrike>> {
                event, gameSession in
                guard var reaction = event.reaction, reaction.reactionCost >= 1 else {
                    return
                }
                guard characterRef == event.characterRef else {
                    return
                }
                guard var me = gameSession.game.anyCharacter(at: characterRef) else {
                    return
                }
                guard
                    !me.conditions.contains(where: {
                        $0.type == ExhaustedMilitaryTacticsCondition.type
                    })
                else {
                    return
                }
                let choice = try await me.brain.decide(
                    .shouldUseMilitaryTactics,
                    options: MilitaryTacticsDecision.allCases,
                    in: gameSession.game.snapshot()
                )
                if choice == .shouldUseMiltaryTactics {
                    await gameSession.game.broadcaster.tellAll(
                        SingleTargetMessage(
                            w1:
                                "$1 relies on their military tactics to strike the fleeing opponent without commiting everything to that reaction.",
                            wU:
                                "You rely on your military tactics to strike the fleeing opponent without commiting everything to that reaction.",
                            as1: characterRef
                        )
                    )
                    reaction.focusCost += 1
                    reaction.reactionCost -= 1
                }
                event.reaction = reaction
                me.conditions.upsert(
                    .init(
                        DurationCondition(
                            core: ExhaustedMilitaryTacticsCondition(),
                            duration: 1,
                            turnsFor: characterRef,
                            tickingAtTurnEnd: false
                        )
                    )
                )
            }
        ]
    }
}

public enum MilitaryTacticsDecision: String, Hashable, Sendable, CaseIterable {
    case shouldUseMiltaryTactics = "use military tactics"
    case shouldNotUseMilitaryTactics = "don't use military tactics"
}

public struct ExhaustedMilitaryTacticsCondition: Condition, ConditionSnapshot {
    public let id: Int
    public var type: ConditionTypeRef = Self.type
    public static let type: ConditionTypeRef = "Exhausted Military Tactics"
    public init(
        in gameSession: isolated GameSession = #isolation
    ) {
        self.id = gameSession.nextId()
    }
}
extension ExhaustedMilitaryTacticsCondition: CustomStringConvertible {
    public var description: String {
        "tapped for military tactics"
    }
}

public struct ExhaustedMilitaryTacticsConditionSnapshot: ConditionSnapshot {
    public let id: Int
    public let type: ConditionTypeRef = ExhaustedMilitaryTacticsCondition.type
}

public struct ShieldBashActionFeature: CharacterFeature, CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { "Shield Bash action" }
    public let actionsProvided: [any CombatAction.Type]
    public init(
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.actionsProvided = [ShieldBashAction.self]
    }
}

public struct ShieldBashAction: CombatAction {
    public let opponentRef: RpgCharacterRef
    public func action(by characterRef: RpgCharacterRef, in gameSession: isolated GameSession)
        async throws
    {
        guard var opponent = gameSession.game.anyCharacter(at: characterRef) else {
            return
        }
        await gameSession.game.broadcaster.tellAll(
            DoubleTargetMessage(
                w12: "$1 gears up to bash $2 with their shield.",
                wU2: "You gear up to bash $2 with your shield.",
                w1U: "$1 gears up to bash you with their shield.", as1: characterRef,
                as2: opponentRef))
        let test = RpgSimpleTest(
            tester: characterRef,
            opponent: opponentRef,
            skill: .core(.athletics),
            difficulty: opponent.defenses[.physical]
        )
        let result = try await test.roll()
        if result.testResult {
            await gameSession.game.broadcaster.tellAll(
                DoubleTargetMessage(
                    w12: "$1 bashes $2 with their shield, knocking them prone.",
                    wU2: "You bash $2 with your shield, knocking them prone.",
                    w1U: "$1 bashes you with their shield, knocking you prone.",
                    as1: characterRef,
                    as2: opponentRef))
            opponent.conditions.upsert(.init(Prone()))
        } else {
            await gameSession.game.broadcaster.tellAll(
                DoubleTargetMessage(
                    w12: "$2 fends off $1's shield bash with sheer athletic might.",
                    wU2: "$2 fends off your shield bash with sheet athletic might.",
                    w1U: "You fend off $1's shield bash with sheer athletic might.",
                    as1: characterRef,
                    as2: opponentRef))
        }
    }
}
