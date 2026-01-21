public enum Realm: Hashable, CaseIterable, Sendable {
    case physical
    case cognitive
    case spiritual
}

public enum AttributeName: Hashable, CaseIterable, Sendable {
    case strength
    case speed
    case intellect
    case awareness
    case willpower
    case presence

    public static let statToRealm: CompleteDictionary<AttributeName, Realm> = [
        .strength: .physical,
        .speed: .physical,
        .intellect: .cognitive,
        .awareness: .cognitive,
        .willpower: .spiritual,
        .presence: .spiritual,
    ]

    public static let realmToAttributes: CompleteDictionary<Realm, Set<AttributeName>> = {
        var result: [Realm: Set<AttributeName>] = [:]
        for (attribute, realm) in statToRealm {
            result[realm, default: Set<AttributeName>()].insert(attribute)
        }
        return CompleteDictionary(from: result)
    }()
}

public enum CoreSkillName: Hashable, CaseIterable, Sendable {
    case agility
    case athletics
    case heavyWeaponry
    case lightWeaponry
    case stealth
    case thievery
    case crafting
    case deduction
    case discipline
    case intimidation
    case lore
    case medicine
    case deception
    case insight
    case leadership
    case perception
    case persuasion
    case survival

    public static let statToSkill: CompleteDictionary<AttributeName, Set<CoreSkillName>> = [
        .strength: [.athletics, .heavyWeaponry],
        .speed: [.agility, .lightWeaponry, .stealth, .thievery],
        .intellect: [.crafting, .deduction, .lore, .medicine],
        .willpower: [.discipline, .intimidation],
        .awareness: [.insight, .perception, .survival],
        .presence: [.deception, .leadership, .persuasion],
    ]

    public static let skillToAttribute: CompleteDictionary<CoreSkillName, AttributeName> = {
        CompleteDictionary(
            from: statToSkill.reduce([CoreSkillName: AttributeName]()) { (initial, x) in
                initial.merging(
                    x.1.map { y in (y, x.0) },
                    uniquingKeysWith: { x, y in
                        fatalError("Core skill associated with multiple attributes: \(x) and \(y)")
                    })
            })
    }()
}

public enum SurgeName: Hashable, CaseIterable, Sendable {
    case division
    case abrasion
    case cohesion
    case adhesion
    case gravitation
    case tension
    case illumination
    case transportation
    case progression
    case transformation
}

public enum SkillName: Hashable, Sendable {
    case core(CoreSkillName)
    case surge(SurgeName)
}

public enum CultureName: CaseIterable {
    case alethi
    case natan
}

public enum Expertise: Hashable {
    case weapon(WeaponName)
    case culture(CultureName)
}

public enum PathName: CaseIterable {
    // Heroic
    case warrior
    case agent
    case envoy
    case hunter
    case leader
    case scholar
    // Radiant
    case dustbringer
    case edgedancer
    case elsecaller
    case lightweaver
    case skybreaker
    case stoneward
    case truthwatcher
    case willshaper
    case windrunner
}

public enum CharacterSize: Sendable {
    case tiny, small, normal, large, huge
}

public struct RpgCharacterRef: Sendable, Hashable {
    public var name: String

    public init(name: String) {
        self.name = name
    }

    public init(of character: any RpgCharacter) {
        self.name = character.name
    }
}

public struct PathProgress {}

public protocol RpgCharacterSharedProtocol: Keyed {
    var name: String { get }
    var attributes: CompleteDictionary<AttributeName, Int> { get }
    var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int> { get }
    var modifiersForCoreSkills: CompleteDictionary<CoreSkillName, Int> { get }  // Derived
    var ranksInOtherSkills: [SkillName: Int] { get }
    var modifiersForOtherSkills: [SkillName: Int] { get }
    var defenses: CompleteDictionary<Realm, Int> { get }
    var health: Resource { get }
    var focus: Resource { get }
    var investiture: Resource { get }
    var recoveryDie: NumberDie { get }
    var sensesRange: Distance { get }
    var movementRate: Distance { get }
    var size: CharacterSize { get }
    var deflect: Int { get }

    var combatState: RpgCharacterCombatState? { get }
}
extension RpgCharacterSharedProtocol {
    public var primaryKey: RpgCharacterRef {
        RpgCharacterRef(name: name)
    }
}
extension RpgCharacterSharedProtocol {
    var modifiers: [SkillName: Int] {
        [SkillName: Int].init(
            uniqueKeysWithValues: modifiersForCoreSkills.map { (cs, v) in (SkillName.core(cs), v) }
                + modifiersForOtherSkills.map { (os, v) in (os, v) })
    }
}

public protocol RpgCharacter: AnyObject, SendableMetatype, RpgCharacterSharedProtocol,
    AllTheListenersHolder,
    NonLeafGenericListenerHolder, Keyed
{
    var game: Game! { get set }
    var brain: any RpgCharacterBrain { get }
    var snapshot: any RpgCharacterSnapshot { get }

    var health: Resource { get set }
    var focus: Resource { get set }
    var investiture: Resource { get set }
    var conditions: KeyedSet<AnyCondition> { get set }
    var equipment: KeyedSet<ReadyableItem> { get set }

    var combatState: RpgCharacterCombatState? { get set }
}

extension RpgCharacter {
    public var childHolders: [Any] {
        conditions.map { $0 as Any } + equipment.map { $0 as Any }
        // TODO something about path progress
    }
}

public protocol FullRpgCharacter: RpgCharacter {
    var expertises: Set<Expertise> { get }
    var money: Money { get }
    var paths: [PathName: PathProgress] { get }
    var level: Int { get }
    var tier: Int { get }
    var maximumSkillRank: Int { get }
}

public struct ReadyableItem {
    public var core: any Item
    public var isReady: Bool
    public init(_ core: any Item, isReady: Bool) {
        self.core = core
        self.isReady = isReady
    }
    public var snapshot: ReadyableItemSnapshot { .init(core.snapshot, isReady: isReady) }
}
extension ReadyableItem: Keyed {
    public var primaryKey: ItemRef {
        core.primaryKey
    }
}

public struct ReadyableItemSnapshot: Sendable {
    public var core: any ItemSnapshot
    public var isReady: Bool
    public init(_ core: any ItemSnapshot, isReady: Bool) {
        self.core = core
        self.isReady = isReady
    }
}
extension ReadyableItemSnapshot: Keyed {
    public var primaryKey: ItemRef {
        core.primaryKey
    }
}

public class PlayerRpgCharacter: FullRpgCharacter {
    public var name: String

    public unowned var game: Game!

    public var size: CharacterSize { .normal }

    public var expertises: Set<Expertise>
    public var equipment: KeyedSet<ReadyableItem>
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

    public var snapshot: any RpgCharacterSnapshot {
        FullRpgCharacterSnapshot(
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
            combatState: combatState,
        )
    }

    public init(
        name: String,
        expertises: Set<Expertise>,
        equipment: KeyedSet<ReadyableItem>,
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
    }
}

public struct FullRpgCharacterSnapshot: RpgCharacterSnapshot {
    public var name: String
    public var attributes: CompleteDictionary<AttributeName, Int>
    public var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int>
    public var modifiersForCoreSkills: CompleteDictionary<CoreSkillName, Int>
    public var ranksInOtherSkills: [SkillName: Int]
    public var modifiersForOtherSkills: [SkillName: Int]
    public var defenses: CompleteDictionary<Realm, Int>
    public var health: Resource
    public var focus: Resource
    public var investiture: Resource
    public var recoveryDie: NumberDie
    public var sensesRange: Distance
    public var conditions: KeyedSet<AnyConditionSnapshot>
    public var movementRate: Distance
    public var size: CharacterSize
    public var deflect: Int
    public var equipment: KeyedSet<ReadyableItemSnapshot>
    public var combatState: RpgCharacterCombatState?
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
            brain: RpgCharacterDummyBrain(characterRef: RpgCharacterRef(name: "Baby son-Daddy")))
    }
}

extension RpgCharacter {
    public var modifiersForCoreSkills: CompleteDictionary<CoreSkillName, Int> {
        ranksInCoreSkills.mapLabeledValues { skill, rank in
            rank + attributes[CoreSkillName.skillToAttribute[skill]]
        }
    }
    public var modifiersForOtherSkills: [SkillName: Int] {
        ranksInOtherSkills.mapLabeledValues { skill, rank in rank }  // TODO
    }
    public var defenses: CompleteDictionary<Realm, Int> {
        CompleteDictionary<Realm, Int>(
            from: [Realm: Int](
                uniqueKeysWithValues:
                    Realm.allCases.map { realm in
                        (
                            realm,
                            AttributeName.realmToAttributes.reduce(10) { (partialDefense, x) in
                                partialDefense
                                    + x.1.map { attribute -> Int in self.attributes[attribute] }
                                    .reduce(0, +)
                            }
                        )
                    }
            ))
    }
    public var movementRate: Distance {
        switch attributes[.speed] {
        case ...0: 20
        case 1...2: 25
        case 3...4: 30
        case 5...6: 40
        case 7...8: 60
        default: 90
        }
    }
    public var recoveryDie: NumberDie {
        switch attributes[.willpower] {
        case ...0: .d4
        case 1...2: .d6
        case 3...4: .d8
        case 5...6: .d10
        case 7...8: .d12
        default: .d20
        }
    }
    public var sensesRange: Distance {
        switch attributes[.awareness] {
        case ...0: 5
        case 1...2: 10
        case 3...4: 20
        case 5...6: 50
        case 7...8: 100
        default: Int.max
        }
    }

    public var deflect: Int {
        0
    }
}

extension FullRpgCharacter {
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

extension RpgCharacter {
    public func takeDamage(_ damage: Damage) {
        let damageReduction = damage.type == .vital ? 0 : deflect
        health.value = max(0, health.value - max(0, damage.amount - damageReduction))
    }
}

// TODO Figure out how to allow all conditions, item traits, environmental factors, and context affect the effective value of all of these numbers. Some conditions should even be contextually determined.
// - Every time you query it, you actually call a function with the number's name as a key.
// - The key could be a complicated enum, or just a Swift key path.
// - Without some level of caching, self could be really expensive.
//   - Time to reinvent pipes, I think. Plus, anytime an attribute's value changes, I could have it send an update. We could bundle those updates and send them to a frontend.
//
// Another option is to make things less declarative and more imperative. I don't want to have to think about self if I don't have to.

// What's the frontend for this thing? I really don't want to be the only person using it, so I think an actual websocket-backed frontend is in order here, with this Swift code running as a backend.

/// Cannot hold one itself recursively. `AnyRpgCharacter(AnyRpgCharacter(someChar)).core === someChar`
public class AnyRpgCharacter: RpgCharacter {
    public var name: String { core.name }
    public var game: Game! {
        get { core.game }
        set { core.game = newValue }
    }
    public var attributes: CompleteDictionary<AttributeName, Int> { core.attributes }
    public var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int> { core.ranksInCoreSkills }
    public var ranksInOtherSkills: [SkillName: Int] { core.ranksInOtherSkills }
    public var health: Resource {
        get { core.health }
        set { core.health = newValue }
    }
    public var focus: Resource {
        get { core.focus }
        set { core.focus = newValue }
    }
    public var investiture: Resource {
        get { core.investiture }
        set { core.investiture = newValue }
    }
    public var conditions: KeyedSet<AnyCondition> {
        get { core.conditions }
        set { core.conditions = newValue }
    }
    public var size: CharacterSize { core.size }
    public var combatState: RpgCharacterCombatState? {
        get { core.combatState }
        set { core.combatState = newValue }
    }
    public var brain: any RpgCharacterBrain { core.brain }
    public var equipment: KeyedSet<ReadyableItem> {
        get { core.equipment }
        set { core.equipment = newValue }
    }
    public var snapshot: any RpgCharacterSnapshot { core.snapshot }
    public var core: any RpgCharacter
    private init(notUnwrapping character: any RpgCharacter) {
        self.core = character
    }
    public convenience init(_ character: any RpgCharacter) {
        if let character = character as? AnyRpgCharacter {
            self.init(character)
        } else {
            self.init(notUnwrapping: character)
        }
    }
}

public protocol RpgCharacterSnapshot: RpgCharacterSharedProtocol, Sendable {
    var conditions: KeyedSet<AnyConditionSnapshot> { get }
    var equipment: KeyedSet<ReadyableItemSnapshot> { get }
}

public struct AnyRpgCharacterSnapshot: RpgCharacterSnapshot {
    public var modifiersForCoreSkills: CompleteDictionary<CoreSkillName, Int> {
        core.modifiersForCoreSkills
    }
    public var modifiersForOtherSkills: [SkillName: Int] { core.modifiersForOtherSkills }
    public var defenses: CompleteDictionary<Realm, Int> { core.defenses }
    public var recoveryDie: NumberDie { core.recoveryDie }
    public var sensesRange: Distance { core.sensesRange }
    public var movementRate: Distance { core.movementRate }
    public var deflect: Int { core.deflect }
    public var name: String { core.name }
    public var attributes: CompleteDictionary<AttributeName, Int> { core.attributes }
    public var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int> { core.ranksInCoreSkills }
    public var ranksInOtherSkills: [SkillName: Int] { core.ranksInOtherSkills }
    public var health: Resource { core.health }
    public var focus: Resource { core.focus }
    public var investiture: Resource { core.investiture }
    public var conditions: KeyedSet<AnyConditionSnapshot> { core.conditions }
    public var size: CharacterSize { core.size }
    public var combatState: RpgCharacterCombatState? { core.combatState }
    public var equipment: KeyedSet<ReadyableItemSnapshot> { core.equipment }
    public var core: any RpgCharacterSnapshot
    private init(notUnwrapping characterSnapshot: any RpgCharacterSnapshot) {
        self.core = characterSnapshot
    }
    public init(_ character: any RpgCharacterSnapshot) {
        if let character = character as? AnyRpgCharacterSnapshot {
            self.init(character)
        } else {
            self.init(notUnwrapping: character)
        }
    }
}
