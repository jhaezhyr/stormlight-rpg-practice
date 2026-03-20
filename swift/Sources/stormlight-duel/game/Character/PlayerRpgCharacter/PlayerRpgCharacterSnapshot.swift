import CompleteDictionary
import KeyedSet

public struct PlayerRpgCharacterSnapshot: RpgCharacterSnapshot {
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
    public var equipment: KeyedSet<Readyable<AnyItemSnapshot>>
    public var mainHand: ItemRef?
    public var offHand: ItemRef?
    public var reach: Distance
    public var combatState: RpgCharacterCombatStateSnapshot?
    public var features: KeyedSet<AnyCharacterFeatureSnapshot>
    public var actions: [any CombatAction.Type]
    public var isPlayer: Bool
}
