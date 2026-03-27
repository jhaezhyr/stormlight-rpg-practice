import KeyedSet
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

extension InteractiveGainAdvantage: CustomStringConvertible {
    public var description: String {
        "gain advantage\(self.opponent.map {" over \($0.name)"} ?? "")\(self.chosenSkill.map {" using \($0)"} ?? "")"
    }
}

public let skillForGainAdvantageOptionDescriber: OptionDescriber<CoreSkillName> = {
    skill, snapshot, characterRef in
    guard let character = snapshot.characters[characterRef] else {
        fatalError("Cannot describe skill for gain advantage action")
    }
    let attribute = skill.attribute
    let bonus = character.modifiersForCoreSkills[skill]
    let drawnWeaponsWithDuplicates: [any WeaponSnapshot] = character.drawnWeapons
    let drawnWeapons = KeyedSet(
        removingDuplicatesFrom: drawnWeaponsWithDuplicates.map(AnyWeaponSnapshot.init))
    let weaponsYouCannotUseThisSkillFor = drawnWeapons.filter { $0.weaponsSkill.coreSkill == skill }
    let warning =
        weaponsYouCannotUseThisSkillFor.count > 0
        ? " [gives no advantage for \(weaponsYouCannotUseThisSkillFor.map { "\($0)" }.joined(separator: " or "))]"
        : ""
    return "\(skill) (\(bonus >= 0 ? "+" : "")\(bonus)) (\(attribute))\(warning)"
}

extension GainAdvantage {
    static let oneLineHelp =
        "Attempt to improve your next strike by finding a target's weakness, using one of your strengths."
}
