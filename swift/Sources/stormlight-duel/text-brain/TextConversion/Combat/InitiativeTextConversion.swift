import stormlight_duel

public let initiativeOptionDescriber: OptionDescriber<CombatTurnInitiativeChoice> = {
    option, y, z in
    switch option {
    case .goNow:
        OptionDescription(
            name: "\(option)",
            oneLineHelp: "Get 2 actions during the fast phase, or 3 during the slow phase")
    case .waitForSlowPhase: OptionDescription(name: "\(option)", oneLineHelp: "Get an extra action")
    case .waitForOthers:
        OptionDescription(
            name: "\(option)", oneLineHelp: "You'll get another chance during this phase")
    }
}
