import stormlight_duel

public let grazeOptionDescriber: OptionDescriber<GrazeChoice> = {
    option, y, z in
    switch option {
    case .shouldGraze:
        OptionDescription(
            name: "\(option)",
            oneLineHelp:
                "Do damage according to your damage die, without your modifier. Costs 1 focus.")
    case .shouldNotGraze:
        OptionDescription(name: "\(option)", oneLineHelp: "Miss the strike and do no damage")
    }
}
