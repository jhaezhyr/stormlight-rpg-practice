import stormlight_duel

extension Recover: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
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
