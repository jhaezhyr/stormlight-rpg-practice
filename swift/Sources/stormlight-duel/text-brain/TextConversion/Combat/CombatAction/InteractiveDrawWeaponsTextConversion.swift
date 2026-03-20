import stormlight_duel

extension InteractiveDrawWeapons: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "w" || firstArgAsString == "draw"
        else {
            return nil
        }
        self.init()
    }

    public static var helpText: Substring {
        "dra(w)"
    }
}

extension InteractiveDrawWeapons: CustomStringConvertible {
    public var description: String { Self.actionName }
}
