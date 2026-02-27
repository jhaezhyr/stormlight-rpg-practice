extension CalculationEventType {
    public static let reactionCostCalculationEvent = Self("reactionCostCalculationEvent")
}

public struct BasicReactionCost: Sendable, Equatable {
    var reactions: Int = 0
    var focus: Int = 0
}

public typealias ReactionCostCalculationEvent = CharacterPropertyCalculationEvent<BasicReactionCost>

public enum ReactionCalculationHook: Sendable, Hashable {
    case couldReact
}

public class ReactionCalculation<R: CombatAction>: Event {
    let hook: ReactionCalculationHook
    let characterRef: RpgCharacterRef
    var reaction: R?

    init(hook: ReactionCalculationHook, for characterRef: RpgCharacterRef, reaction: R) {
        self.hook = hook
        self.reaction = reaction
        self.characterRef = characterRef
    }
}

public typealias CombatReaction = CombatAction
