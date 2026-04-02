import stormlight_duel

extension TakeAimAction: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        guard let firstArg = args.first as? Substring, firstArg.lowercased() == "takeaim" else {
            return nil
        }
        guard
            let gainAdvantageAction = try InteractiveGainAdvantage.init(
                args: ["g" as Substring] + args.dropFirst(), context: context)
        else {
            return nil
        }
        self.init(opponent: gainAdvantageAction.opponent, skill: gainAdvantageAction.chosenSkill)
    }

    public static var helpText: Substring {
        "takeaim [\(CoreSkillName.helpText)] [\(RpgCharacterRef.helpText)]"
    }
    public static let oneLineHelp: String? =
        "On your first turn, you may take Gain Advantage as a free action"
}

extension TakeAimAction: CustomStringConvertible, DescribableOption {
    public var description: String {
        "take aim\(self.opponent.map {" at \($0.name)"} ?? "")\(self.skill.map {" using \($0)"} ?? "")"
    }
}
