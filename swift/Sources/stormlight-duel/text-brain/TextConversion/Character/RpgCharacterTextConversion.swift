import stormlight_duel

extension RpgCharacterRef: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsedName = args.first as? RpgCharacterRef, args.count == 1 {
            self = alreadyParsedName
            return
        }
        if let string = args.first as? Substring {
            let ref = RpgCharacterRef(name: String(string))
            if context.game.characters.contains(ref) {
                self = ref
                return
            } else {
                // Maybe this isn't supposed to be a character?
                return nil
            }
        }
        throw CliParseError("\(args) is not a name")
    }
    public static var helpText: Substring { "<character>" }
}
