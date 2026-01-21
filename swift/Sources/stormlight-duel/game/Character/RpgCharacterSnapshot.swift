public protocol RpgCharacterSnapshot: RpgCharacterSharedProtocol, Sendable {
    var conditions: KeyedSet<AnyConditionSnapshot> { get }
    var equipment: KeyedSet<Readyable<AnyItemSnapshot>> { get }
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
    public var equipment: KeyedSet<Readyable<AnyItemSnapshot>> { core.equipment }
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
