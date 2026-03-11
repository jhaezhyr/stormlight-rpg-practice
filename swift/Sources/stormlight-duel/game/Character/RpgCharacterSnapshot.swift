import CompleteDictionary
import KeyedSet

public protocol RpgCharacterSnapshot: RpgCharacterSharedProtocol, Sendable
where
    CharacterFeatureType == AnyCharacterFeatureSnapshot,
    ItemType == AnyItemSnapshot,
    ConditionType == AnyConditionSnapshot,
    CombatState == RpgCharacterCombatStateSnapshot
{
    var deflect: Int { get }
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
    public var conditions: KeyedSet<AnyConditionSnapshot> {
        get { core.conditions }
        set { core.conditions = newValue }
    }
    public var size: CharacterSize { core.size }
    public var combatState: RpgCharacterCombatStateSnapshot? { core.combatState }
    public var features: KeyedSet<AnyCharacterFeatureSnapshot> { core.features }
    public var actions: [any CombatAction.Type] { core.actions }
    public var equipment: KeyedSet<Readyable<AnyItemSnapshot>> {
        get { core.equipment }
        set { core.equipment = newValue }
    }
    public var mainHand: ItemRef? {
        get { core.mainHand }
        set { core.mainHand = newValue }
    }
    public var offHand: ItemRef? {
        get { core.offHand }
        set { core.offHand = newValue }
    }
    public var reach: Distance { core.reach }
    public var isPlayer: Bool { core.isPlayer }
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

extension RpgCharacterSharedProtocol {
    var readyItems: [ItemType] {
        equipment.compactMap { $0.isReady ? $0.core : nil }
    }
}
