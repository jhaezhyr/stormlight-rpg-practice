import stormlight_duel

extension InteractiveMove: CliArgsContextFreeConvertibleType, DescribableOption {
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
    public static var oneLineHelp: String? {
        "Move up to your movement rate"
    }
}

extension Direction1D: CliArgsContextFreeConvertibleType, DescribableOption {
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

    public func optionDescription(context: CliArgsConversionContext) -> OptionDescription {
        switch self {
        case .left: OptionDescription(name: "(l)eft")
        case .right: OptionDescription(name: "(r)ight")
        }
    }
}

extension DecideOrOther: DescribableOption where T: DescribableOption {
    public func optionDescription(context: CliArgsConversionContext) -> OptionDescription {
        switch self {
        case .decide(let option):
            option.optionDescription(context: context)
        case .other(let other):
            OptionDescription(name: other)
        }
    }
}

extension InteractiveMove: CustomStringConvertible {
    public var description: String { "move" }
}
extension InteractiveMove {
    public static func oneLineHelp(_ character: any RpgCharacterSnapshot) -> String {
        "Move up to \(character.movementRate)ft"
    }
}
