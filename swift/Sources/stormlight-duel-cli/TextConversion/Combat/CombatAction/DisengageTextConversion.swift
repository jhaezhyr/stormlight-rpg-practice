import stormlight_duel

extension DisengageAction: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedGainAdvantage = args.first as? Self, args.count == 1 {
            self = alreadyParsedGainAdvantage
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "d" || firstArgAsString == "disengage"
        else {
            return nil
        }
        var direction: Direction1D?
        for arg in remaining {
            if let directionArg = try Direction1D(args: [arg]), direction == nil {
                direction = directionArg
            } else {
                throw CliParseError("\(arg) not a direction")
            }
        }
        guard let direction = direction else {
            throw CliParseError("No direction established for disengage.")
        }
        self.init(direction: direction)
    }

    static var helpText: Substring {
        "(d)isengage \(Direction1D.helpText)"
    }
}
