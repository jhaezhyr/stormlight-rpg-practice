import stormlight_duel

extension DisengageAction: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedGainAdvantage = args.first as? Self, args.count == 1 {
            self = alreadyParsedGainAdvantage
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
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

    public static var helpText: Substring {
        "(d)isengage \(Direction1D.helpText)"
    }
    public static var oneLineHelp: String? {
        "Move 5ft without triggering reactive strikes"
    }
}
