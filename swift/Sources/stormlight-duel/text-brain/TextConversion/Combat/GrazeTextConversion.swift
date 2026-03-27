import stormlight_duel

public let grazeOptionDescriber: OptionDescriber<GrazeChoice> = {
    option, y, z in
    switch option {
    case .shouldGraze:
        "Do damage according to your damage die, without your modifier. Costs 1 focus."
    case .shouldNotGraze: "Miss the strike and do no damage"
    }
}
