import CompleteDictionary
import KeyedSet

public struct RpgCharacterRef: Sendable, Hashable {
    public var name: String

    public init(name: String) {
        self.name = name
    }

    public init(of character: any RpgCharacter) {
        self.name = character.name
    }
}

public protocol RpgCharacterSharedProtocol: Keyed where Key == RpgCharacterRef {
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
    /// You can only do touch/melee when your space is within `reach` of your target.
    var reach: Distance { get }

    associatedtype CombatState: RpgCharacterCombatStateSharedProtocol
    var combatState: CombatState? { get }
    associatedtype CharacterFeatureType: CharacterFeatureSharedProtocol
    var features: KeyedSet<CharacterFeatureType> { get }
    var actions: [CombatAction.Type] { get }

    /// Whether this character is controlled by a game player, instead of the game master.
    var isPlayer: Bool { get }

    associatedtype ConditionType: ConditionSharedProtocol
    var conditions: KeyedSet<ConditionType> { get set }
    associatedtype ItemType: ItemSharedProtocol
    var equipment: KeyedSet<Readyable<ItemType>> { get set }
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

public protocol RpgCharacter: AnyObject,
    RpgCharacterSharedProtocol,
    SendableMetatype,
    Responder
where
    CharacterFeatureType == AnyCharacterFeature,
    ConditionType == AnyCondition,
    ItemType == AnyItem
{
    var brain: any RpgCharacterBrain { get }
    func _snapshot(in gameSession: isolated GameSession) -> any RpgCharacterSnapshot

    var health: Resource { get set }
    var focus: Resource { get set }
    var investiture: Resource { get set }

    var combatState: RpgCharacterCombatState? { get set }
}

extension RpgCharacter {
    public var childResponders: [any Responder] {
        conditions.map { $0.core as any Responder }
            + equipment.map { $0.core as any Responder }
            + (combatState?.reactionProviders ?? [])
            + features.map { $0.core as any Responder }
        // TODO something about path progress
    }
}
extension RpgCharacter {
    func snapshot(in gameSession: isolated GameSession = #isolation) -> any RpgCharacterSnapshot {
        _snapshot(in: gameSession)
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
                            AttributeName.realmToAttributes[realm].reduce(10) {
                                (partialDefense, attributeName) in
                                partialDefense + self.attributes[attributeName]
                            }
                        )
                    }
            ))
    }
    public var movementRate: Distance {
        guard !self.conditions.contains(where: { $0.type == Immobilized.type }) else {
            return 0
        }
        return switch attributes[.speed] {
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
        // TODO Decentralize this logic. Make a "modified value" object.
        equipment.map { readyable in
            readyable.isReady ? (readyable.core.core as? any Armor)?.deflect ?? 0 : 0
        }.reduce(0, +)
    }
}

/// Returns the damage actually taken.
public func doDamage(
    _ damage: Damage, to characterRef: RpgCharacterRef,
    in gameSession: isolated GameSession = #isolation
)
    async -> Damage
{
    guard let character = gameSession.game.anyCharacter(at: characterRef) else {
        return Damage(0, type: damage.type)
    }
    let damageReduction: Int
    if character.deflect > 0 {
        if damage.type == .vital {
            await gameSession.game.broadcaster.tellAll(
                SingleTargetMessage(
                    w1: "$1 can't deflect vital damage.", wU: "You can't deflect vital damage.",
                    as1: character.primaryKey))
            damageReduction = 0
        } else {
            await gameSession.game.broadcaster.tellAll(
                SingleTargetMessage(
                    w1:
                        "$1 deflects \(character.deflect >= damage.amount ? "all" : "\(character.deflect)") of the incoming \(damage.type) damage.",
                    wU:
                        "You deflect \(character.deflect >= damage.amount ? "all" : "\(character.deflect)") of the incoming \(damage.type) damage.",
                    as1: character.primaryKey)
            )
            damageReduction = character.deflect
        }
    } else {
        damageReduction = 0
    }
    let oldHealth = character.health.value
    character.health.value = max(
        0, character.health.value - max(0, damage.amount - damageReduction))
    return Damage(oldHealth - character.health.value, type: damage.type)
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
    public var features: KeyedSet<AnyCharacterFeature> { core.features }
    public var actions: [any CombatAction.Type] { core.actions }
    public var brain: any RpgCharacterBrain { core.brain }
    public var equipment: KeyedSet<Readyable<AnyItem>> {
        get { core.equipment }
        set { core.equipment = newValue }
    }
    public var reach: Distance { core.reach }
    public var isPlayer: Bool { core.isPlayer }
    public func _snapshot(in gameSession: isolated GameSession)
        -> any RpgCharacterSnapshot
    {
        core._snapshot(in: gameSession)
    }
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
extension AnyRpgCharacter: CustomStringConvertible {
    public var description: String {
        "\(name) (\(type(of: self)) wrapping \(type(of: core)))"
    }
}
