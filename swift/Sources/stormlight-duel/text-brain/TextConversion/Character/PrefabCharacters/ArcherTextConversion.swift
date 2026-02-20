import stormlight_duel

extension TakeAimAction: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        guard let firstArg = args.first as? Substring, firstArg == "takeaim" else {
            return nil
        }
        guard
            let gainAdvantageAction = try GainAdvantage.init(
                args: ["g" as Substring] + args.dropFirst(), context: context)
        else {
            return nil
        }
        self.init(opponent: gainAdvantageAction.opponent, skill: gainAdvantageAction.chosenSkill)
    }

    public static var helpText: Substring {
        "takeaim \(CoreSkillName.helpText) [\(RpgCharacterRef.helpText)]"
    }
}
