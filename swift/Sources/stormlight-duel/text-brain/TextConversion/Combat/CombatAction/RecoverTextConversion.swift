import stormlight_duel

extension InteractiveRecover: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "r" || firstArgAsString == "recover"
        else {
            return nil
        }
        self.init()
    }

    public static var helpText: Substring {
        "(r)ecover"
    }
}

extension InteractiveRecover: CustomStringConvertible {
    public var description: String { Self.actionName }
}

extension HowToRecover: CustomStringConvertible {
    public var description: String {
        "restore \(amountHealth) health and \(amountFocus) focus\(amountLeftover > 0 ? ", leaving \(amountLeftover) leftover" : "")"
    }
}
