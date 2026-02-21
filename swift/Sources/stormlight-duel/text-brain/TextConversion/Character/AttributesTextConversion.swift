import stormlight_duel

extension CoreSkillName: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedSkill = args.first as? Self, args.count == 1 {
            self = alreadyParsedSkill
            return
        }
        if let string = args.first as? Substring,
            let skill = CoreSkillName(caseInsensitiveRawValue: String(string))
        {
            self = skill
            return
        }
        throw CliParseError("\(args) is not a core skill")
    }

    public static var helpText: Substring {
        "<core skill>"
    }
}
