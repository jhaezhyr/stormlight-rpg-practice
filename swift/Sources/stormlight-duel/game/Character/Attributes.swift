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

public enum CoreSkillName: String, Hashable, CaseIterable, Sendable {
    case agility = "agility"
    case athletics = "athletics"
    case heavyWeaponry = "heavy"
    case lightWeaponry = "light"
    case stealth = "stealth"
    case thievery = "thievery"
    case crafting = "crafting"
    case deduction = "deduction"
    case discipline = "discipline"
    case intimidation = "intimidation"
    case lore = "lore"
    case medicine = "medicine"
    case deception = "deception"
    case insight = "insight"
    case leadership = "leadership"
    case perception = "perception"
    case persuasion = "persuasion"
    case survival = "survival"

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

    public var attribute: AttributeName {
        Self.skillToAttribute[self]
    }
    public var realm: Realm {
        AttributeName.statToRealm[attribute]
    }
}
extension CoreSkillName: CustomStringConvertible {
    public var description: String { rawValue }
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
public enum CharacterSize: Sendable {
    case tiny, small, normal, large, huge
}
