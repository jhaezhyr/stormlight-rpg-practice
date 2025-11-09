enum Realm: Hashable, CaseIterable {
    case physical
    case cognitive
    case spiritual
}

enum AttributeName: Hashable, CaseIterable {
    case strength
    case speed
    case intellect
    case awareness
    case willpower
    case presence

    static let statToRealm: CompleteDictionary<AttributeName, Realm> = [
        .strength: .physical,
        .speed: .physical,
        .intellect: .cognitive,
        .awareness: .cognitive,
        .willpower: .spiritual,
        .presence: .spiritual,
    ]

    static let realmToAttributes: CompleteDictionary<Realm, Set<AttributeName>> = {
        var result: [Realm: Set<AttributeName>] = [:]
        for (attribute, realm) in statToRealm {
            result[realm, default: Set<AttributeName>()].insert(attribute)
        }
        return CompleteDictionary(from: result)
    }()
}

enum CoreSkillName: Hashable, CaseIterable {
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

    static let statToSkill: CompleteDictionary<AttributeName, Set<CoreSkillName>> = [
        .strength: [.athletics, .heavyWeaponry],
        .speed: [.agility, .lightWeaponry, .stealth, .thievery],
        .intellect: [.crafting, .deduction, .lore, .medicine],
        .willpower: [.discipline, .intimidation],
        .awareness: [.insight, .perception, .survival],
        .presence: [.deception, .leadership, .persuasion],
    ]

    static let skillToAttribute: CompleteDictionary<CoreSkillName, AttributeName> = {
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

enum SurgeName: Hashable, CaseIterable {
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

enum SkillName: Hashable {
    case core(CoreSkillName)
    case surge(SurgeName)
}

enum CultureName: CaseIterable {
    case alethi
    case natan
}

enum Expertise: Hashable {
    case weapon(WeaponName)
    case culture(CultureName)
}

enum PathName: CaseIterable {
    // Heroic
    case warrior
    case agent
    case envoy
    case unter
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

enum CharacterSize {
    case tiny, small, normal, large, huge
}

struct PathProgress {}

protocol Character {
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
    var conditions: [Condition] { get }
    var movementRate: Distance { get }
    var size: CharacterSize { get }
}

protocol FullCharacter: Character {
    var expertises: Set<Expertise> { get }
    var equipment: [Item] { get }
    var money: Money { get }
    var paths: [PathName: PathProgress] { get }
    var level: Int { get }
    var tier: Int { get }
    var maximumSkillRank: Int { get }
}

struct PlayerCharacter: FullCharacter {
    let size: CharacterSize = .normal

    var expertises: Set<Expertise>
    var equipment: [any Item]
    var money: Money
    var paths: [PathName: PathProgress]

    var level: Int

    var attributes: CompleteDictionary<AttributeName, Int>

    var ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int>
    var ranksInOtherSkills: [SkillName: Int]

    var health: Resource
    var focus: Resource
    var investiture: Resource

    var conditions: [Condition]
}

extension Character {
    var modifiersForCoreSkills: CompleteDictionary<CoreSkillName, Int> {
        ranksInCoreSkills.mapLabeledValues { skill, rank in
            rank + attributes[CoreSkillName.skillToAttribute[skill]]
        }
    }
    var modifiersForOtherSkills: [SkillName: Int] {
        ranksInOtherSkills.mapLabeledValues { skill, rank in rank }  // TODO
    }
    var defenses: CompleteDictionary<Realm, Int> {
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
    var movementRate: Distance {
        switch attributes[.speed] {
        case ...0: 20
        case 1...2: 25
        case 3...4: 30
        case 5...6: 40
        case 7...8: 60
        default: 90
        }
    }
    var recoveryDie: NumberDie {
        switch attributes[.willpower] {
        case ...0: .d4
        case 1...2: .d6
        case 3...4: .d8
        case 5...6: .d10
        case 7...8: .d12
        default: .d20
        }
    }
    var sensesRange: Distance {
        switch attributes[.awareness] {
        case ...0: 5
        case 1...2: 10
        case 3...4: 20
        case 5...6: 50
        case 7...8: 100
        default: Int.max
        }
    }
}

extension FullCharacter {
    var tier: Int {
        switch level {
        case ...5: 1
        case ...10: 2
        case ...15: 3
        case ...20: 4
        default: 5
        }
    }
    var maximumSkillRank: Int {
        max(5, tier + 1)
    }
}

// TODO Figure out how to allow all conditions, item traits, environmental factors, and context affect the effective value of all of these numbers. Some conditions should even be contextually determined.
// - Every time you query it, you actually call a function with the number's name as a key.
// - The key could be a complicated enum, or just a Swift key path.
// - Without some level of caching, this could be really expensive.
//   - Time to reinvent pipes, I think. Plus, anytime an attribute's value changes, I could have it send an update. We could bundle those updates and send them to a frontend.
//
// Another option is to make things less declarative and more imperative. I don't want to have to think about this if I don't have to.

// What's the frontend for this thing? I really don't want to be the only person using it, so I think an actual websocket-backed frontend is in order here, with this Swift code running as a backend.
