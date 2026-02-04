public enum DecisionCode: Sendable, Equatable {
    case shouldGraze
    case initiative
    case combatChoice
    case whichDieToModify(_ modifier: RollModifier)
    case shouldDodge
    case skillForGainAdvantage
    case howToRecover
}

extension DecisionCode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .shouldGraze:
            "You missed. Would you like to graze?"
        case .initiative:
            "Would you like to take your turn now?"
        case .combatChoice:
            "What action will you take?"
        case .whichDieToModify(let modifier):
            "Which die would you like to \(modifier) in this test?"
        case .shouldDodge:
            "You're being targeted. Would you like to dodge?"
        case .skillForGainAdvantage:
            "Which skill would you like to use to gain advantage over your opponent?"
        case .howToRecover:
            "How would you like to use this point of recovery?"
        }
    }
}
