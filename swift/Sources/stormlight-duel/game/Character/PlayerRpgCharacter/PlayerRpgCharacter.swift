import CompleteDictionary
import KeyedSet

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

    public var reach: Distance

    public var features: KeyedSet<AnyCharacterFeature>

    public var conditions: KeyedSet<AnyCondition>

    public var brain: any RpgCharacterBrain

    public var combatState: RpgCharacterCombatState?
    public var actions: [any CombatAction.Type] {
        allCombatActions + self.features.flatMap { $0.actionsProvided }
    }

    public var isPlayer: Bool

    public func _snapshot(in gameSession: isolated GameSession = #isolation)
        -> any RpgCharacterSnapshot
    {
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
            conditions: .init(conditions.isolatedMap { AnyConditionSnapshot($0.snapshot(in: $1)) }),
            movementRate: movementRate,
            size: size,
            deflect: deflect(),
            equipment: .init(equipment.isolatedMap { $0.snapshot(in: $1) }),
            reach: reach,
            combatState: combatState?.snapshot(),
            features: .init(
                features.isolatedMap { AnyCharacterFeatureSnapshot($0.snapshot(in: $1)) }),
            actions: actions,
            isPlayer: isPlayer,
        )
    }

    @discardableResult
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
        reach: Distance,
        features: KeyedSet<AnyCharacterFeature>,
        conditions: KeyedSet<AnyCondition>,
        brain: any RpgCharacterBrain,
        combatState: RpgCharacterCombatState? = nil,
        isPlayer: Bool,
        andAddTo gameSession: isolated GameSession,
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
        self.reach = reach
        self.features = features
        self.conditions = conditions
        self.brain = brain
        self.combatState = combatState
        self.isPlayer = isPlayer
    }
}

extension PlayerRpgCharacter {
    @discardableResult
    public static func basicCharacter(
        name: String = "Baby son-Daddy",
        brain: (any RpgCharacterBrain)? = nil,
        andAddTo gameSession: isolated GameSession,
    ) -> PlayerRpgCharacter {
        let brain = brain ?? RpgCharacterDummyBrain(characterRef: RpgCharacterRef(name: name))
        return PlayerRpgCharacter(
            name: name,
            expertises: [],
            equipment: [],
            attributes: [
                .strength: 2, .speed: 1, .intellect: 2, .awareness: 2, .presence: 2, .willpower: 2,
            ],
            ranksInCoreSkills: .init(
                from: .init(uniqueKeysWithValues: CoreSkillName.allCases.map { ($0, 0) })
            ),
            ranksInOtherSkills: [:],
            health: .init(value: 12, maxValue: 12),
            focus: .init(value: 4, maxValue: 4),
            investiture: .init(value: 0, maxValue: 0),
            reach: 0,
            features: [],
            conditions: [],
            brain: brain,
            isPlayer: true,
            andAddTo: gameSession,
        )
    }
}

extension PlayerRpgCharacter: CustomStringConvertible {
    public var description: String {
        "\(name) (\(type(of: self)))"

    }
}
