import stormlight_duel

extension CoreSkillName: CliArgsContextFreeConvertibleType {
    init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedSkill = args.first as? Self, args.count == 1 {
            self = alreadyParsedSkill
            return
        }
        if let string = args.first as? Substring,
            let skill = CoreSkillName(rawValue: String(string))
        {
            self = skill
            return
        }
        throw CliParseError("\(args) is not a core skill")
    }

    static var helpText: Substring {
        "<core skill>"
    }
}
