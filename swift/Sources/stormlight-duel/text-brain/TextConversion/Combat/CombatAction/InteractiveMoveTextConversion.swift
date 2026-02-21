import stormlight_duel

extension InteractiveMove: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedMove = args.first as? InteractiveMove, args.count == 1 {
            self = alreadyParsedMove
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "m" || firstArgAsString == "move"
        else {
            return nil
        }
        self.init()
    }

    public static var helpText: Substring { "(m)ove" }
}

extension Direction1D: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "r" || firstArgAsString == "l"
        else {
            return nil
        }
        self = firstArgAsString == "r" ? .right : .left
    }

    public static var helpText: Substring {
        "R|L"
    }
}

extension InteractiveMove: CustomStringConvertible {
    public var description: String { "move" }
}
