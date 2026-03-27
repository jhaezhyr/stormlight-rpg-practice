public enum DecisionCode: Sendable, Equatable, Hashable {
    case understanding
    case shouldGraze
    case initiative
    case combatChoice
    case whichDieToModify(_ modifier: RollModifier)
    case shouldDodge
    case skillForGainAdvantage
    case howToRecover
    case directionToMove5Ft
    case reactiveStrikeChoice
    case shouldShootImmobilizingShot
    case opportunityChoice
    case complicationChoice
    case targetForGainAdvantage
    case shouldUseMilitaryTactics
    case shouldStandStrongInComingStorm
    case drawWeaponsChoice(Hand)
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
        case .directionToMove5Ft:
            "Which direction would you like to move 5ft?"
        case .reactiveStrikeChoice:
            "Your opponent is trying to flee! Will you strike?"
        case .shouldShootImmobilizingShot:
            "Your opponent has moved. Will you try to immobilize them?"
        case .opportunityChoice:
            "You have an opportunity! How would you like to spend it?"
        case .complicationChoice:
            "The test has a complication! How would you like to spend it?"
        case .targetForGainAdvantage:
            "Which character will you try to exploit?"
        case .shouldUseMilitaryTactics:
            "You can use your military tactics once per round to Aid or Reactive Strike by spending an extra focus instead of your reaction."
        case .shouldStandStrongInComingStorm:
            "Will you divert your focus to staying upright?"
        case .drawWeaponsChoice(let hand):
            "You have the following weapons available to you. Which will go in your \(hand)?"
        case .understanding:
            """
            Welcome to STORMLIGHT DUEL!

            This videogame experience is based on the "Cosmere Roleplaying Game" by
            Brotherwise Games, based on works by Brandon Sanderson. The videogame is
            written and hosted by Braeden Hintze.

                        * ** INSTRUCTIONS ** * 

            You have a single opponent. Bring them down.

            Anytime you are prompted to make a choice, you type in your answer and
            press ENTER. In some cases, you are given multiple numbered options. In
            other cases, your choices are a list of one-word commands. Some commands
            have single-letter aliases to make them easier to type.

            When the game waits for your input, you also can type "status" in order
            to see the map and the conditions of both characters. The map shows a
            letter for each character, and a . for every 5ft distance. The map is
            1-dimensional to keep things simple and brutal.

            Do you understand?
            """
        }
    }
}
