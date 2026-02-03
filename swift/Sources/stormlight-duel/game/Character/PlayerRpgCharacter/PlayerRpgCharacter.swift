/// Many characters have stat blocks, but only full characters have expertises, money, and paths.
public protocol PlayerRpgCharacterProtocol: RpgCharacter {
    var expertises: Set<Expertise> { get }
    var money: Money { get }
    var paths: [PathName: PathProgress] { get }
    var level: Int { get }
    var tier: Int { get }
    var maximumSkillRank: Int { get }
}

extension PlayerRpgCharacterProtocol {
    public var tier: Int {
        switch level {
        case ...5: 1
        case ...10: 2
        case ...15: 3
        case ...20: 4
        default: 5
        }
    }
    public var maximumSkillRank: Int {
        max(5, tier + 1)
    }
}

public class PlayerRpgCharacter: PlayerRpgCharacterProtocol {

    public var name: String

    public unowned var game: Game!

    public var size: CharacterSize { .normal }

    public var expertises: Set<Expertise>
    public var equipment: KeyedSet<Readyable<AnyItem>>
    public var money: Money = 0
    public var paths: [PathName: PathProgress] = [:]

    public var level: Int = 1

    public var attributes: CompleteDictionary<AttributeName, Int>

    public var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int>
    public var ranksInOtherSkills: [SkillName: Int]

    public var health: Resource
    public var focus: Resource
    public var investiture: Resource

    public var conditions: KeyedSet<AnyCondition>

    public var brain: any RpgCharacterBrain

    public var combatState: RpgCharacterCombatState?

    public var isPlayer: Bool

    public var snapshot: any RpgCharacterSnapshot {
        PlayerRpgCharacterSnapshot(
            name: name,
            attributes: attributes,
            ranksInCoreSkills: ranksInCoreSkills,
            modifiersForCoreSkills: modifiersForCoreSkills,
            ranksInOtherSkills: ranksInOtherSkills,
            modifiersForOtherSkills: modifiersForOtherSkills,
            defenses: defenses,
            health: health,
            focus: focus,
            investiture: investiture,
            recoveryDie: recoveryDie,
            sensesRange: sensesRange,
            conditions: .init(conditions.map { AnyConditionSnapshot($0.snapshot) }),
            movementRate: movementRate,
            size: size,
            deflect: deflect,
            equipment: .init(equipment.map { $0.snapshot }),
            combatState: combatState?.snapshot,
            isPlayer: isPlayer,
        )
    }

    public init(
        name: String,
        expertises: Set<Expertise>,
        equipment: KeyedSet<Readyable<AnyItem>>,
        money: Money = 0,
        paths: [PathName: PathProgress] = [:],
        level: Int = 1,
        attributes: CompleteDictionary<AttributeName, Int>,
        ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int>,
        ranksInOtherSkills: [SkillName: Int],
        health: Resource,
        focus: Resource,
        investiture: Resource,
        conditions: KeyedSet<AnyCondition>,
        brain: any RpgCharacterBrain,
        combatState: RpgCharacterCombatState? = nil,
        isPlayer: Bool,
    ) {
        self.name = name
        self.expertises = expertises
        self.equipment = equipment
        self.money = money
        self.paths = paths
        self.level = level
        self.attributes = attributes
        self.ranksInCoreSkills = ranksInCoreSkills
        self.ranksInOtherSkills = ranksInOtherSkills
        self.health = health
        self.focus = focus
        self.investiture = investiture
        self.conditions = conditions
        self.brain = brain
        self.combatState = combatState
        self.isPlayer = isPlayer
    }
}

extension PlayerRpgCharacter {
    public static func basicCharacter() -> PlayerRpgCharacter {
        PlayerRpgCharacter(
            name: "Baby son-Daddy", expertises: [], equipment: [],
            attributes: [
                .strength: 2, .speed: 1, .intellect: 2, .awareness: 2, .presence: 2, .willpower: 2,
            ],
            ranksInCoreSkills: .init(
                from: .init(uniqueKeysWithValues: CoreSkillName.allCases.map { ($0, 0) })),
            ranksInOtherSkills: [:], health: .init(value: 12, maxValue: 12),
            focus: .init(value: 4, maxValue: 4),
            investiture: .init(value: 0, maxValue: 0), conditions: [],
            brain: RpgCharacterDummyBrain(characterRef: RpgCharacterRef(name: "Baby son-Daddy")),
            isPlayer: true
        )
    }
}
