import stormlight_duel

extension InteractiveGainAdvantage: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsedGainAdvantage = args.first as? Self, args.count == 1 {
            self = alreadyParsedGainAdvantage
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "g" || firstArgAsString == "gainadv"
        else {
            return nil
        }
        var target: RpgCharacterRef?
        var skill: CoreSkillName?
        for arg in remaining {
            if let skillArg = try CoreSkillName(args: [arg], context: context), skill == nil {
                skill = skillArg
            } else if let targetArg = try RpgCharacterRef(args: [arg], context: context),
                target == nil
            {
                target = targetArg
            } else {
                throw CliParseError("\(arg) not a target or core skill")
            }
        }
        self.init(opponent: target, chosenSkill: skill)
    }

    public static var helpText: Substring {
        "(g)ainadv \(CoreSkillName.helpText) [target]"
    }
}
