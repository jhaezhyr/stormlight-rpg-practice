import stormlight_duel

extension RpgCharacterRef: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedName = args.first as? RpgCharacterRef, args.count == 1 {
            self = alreadyParsedName
            return
        }
        if let string = args.first as? Substring {
            self = RpgCharacterRef(name: String(string))
            return
        }
        throw CliParseError("\(args) is not a name")
    }
    public static var helpText: Substring { "<character>" }
}
