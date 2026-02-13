import stormlight_duel

extension GainAdvantage: CliArgsConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsedGainAdvantage = args.first as? Self, args.count == 1 {
            self = alreadyParsedGainAdvantage
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = firstArg as? Substring,
            firstArgAsString == "g" || firstArgAsString == "gainadv"
        else {
            return nil
        }
        var target: RpgCharacterRef?
        var skill: CoreSkillName?
        guard let contextCharacter = context.game.characters[context.characterRef] else {
            throw CliParseError("Bad character ref \(context.characterRef)")
        }
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
        // What if the target wasn't provided?
        let realTarget: RpgCharacterRef = try
            ({ (x: ()) throws(CliParseError) in
                if let target {
                    return target
                } else {
                    let characters = context.game.characters
                    let viableTargets = characters.filter {
                        $0.primaryKey != contextCharacter.primaryKey && $0.health.value > 0
                    }
                    if viableTargets.count != 1 {
                        throw CliParseError(
                            "It seems \(contextCharacter.name) has \(viableTargets.count) available targets: \(viableTargets)"
                        )
                    }
                    return viableTargets[0].primaryKey
                }
            })(())
        let realSkill: CoreSkillName = try { (x: ()) throws(CliParseError) in
            if let skill {
                return skill
            }
            throw CliParseError("No skill was chosen for the Gain Advantage action.")
        }(())
        self.init(opponent: realTarget, skill: realSkill)
    }

    static var helpText: Substring {
        "(g)ainadv [skill] [target]"
    }
}
