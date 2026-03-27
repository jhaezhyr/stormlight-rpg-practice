import stormlight_duel

public let initiativeOptionDescriber: OptionDescriber<CombatTurnInitiativeChoice> = {
    option, y, z in
    switch option {
    case .goNow: "\(option)\n  ? Get 2 actions during the fast phase, or 3 during the slow phase"
    case .waitForSlowPhase: "\(option)\n  ? Get an extra action"
    case .waitForOthers: "\(option)\n  ? You'll get another chance during this phase"
    }
}
