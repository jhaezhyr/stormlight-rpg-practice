import stormlight_duel

extension Strike: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsedStrike = args.first as? Strike, args.count == 1 {
            self = alreadyParsedStrike
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "k" || firstArgAsString == "strike"
        else {
            return nil
        }
        var target: RpgCharacterRef?
        var weaponToStrikeWith: ItemRef?
        guard let contextCharacter = context.game.characters[context.characterRef] else {
            throw CliParseError("Bad character ref \(context.characterRef)")
        }
        for arg in remaining {
            if let targetArg = try RpgCharacterRef(args: [arg], context: context), target == nil {
                target = targetArg
            } else if let weaponArg = try WeaponName(args: [arg], context: context),
                weaponToStrikeWith == nil
            {
                let weaponToStrikeWithCandidates = contextCharacter.equipment.filter {
                    ($0.core.core as? any Weapon)?.weaponName == weaponArg
                }
                if weaponToStrikeWithCandidates.count == 0 {
                    throw CliParseError("\(arg) is not a weapon that \(contextCharacter.name) has")
                } else if weaponToStrikeWithCandidates.count > 1 {
                    let readyWeaponCandidates = weaponToStrikeWithCandidates.filter { $0.isReady }
                    if readyWeaponCandidates.count != 1 {
                        throw CliParseError(
                            "\(arg) is a weapon that \(contextCharacter.name) has two or more of, and \(readyWeaponCandidates.count) are ready"
                        )
                    } else {
                        weaponToStrikeWith = readyWeaponCandidates[0].primaryKey
                    }
                } else {
                    weaponToStrikeWith = weaponToStrikeWithCandidates[0].primaryKey
                }
            } else {
                throw CliParseError("\(arg) not a target or weapon name")
            }
        }
        let possibleStrikes = Strike.possibleStrikes(
            for: context.characterRef, in: context.game, target: target, weapon: weaponToStrikeWith)
        // What if the target wasn't provided?
        if possibleStrikes.isEmpty {
            throw CliParseError(
                "You have at least one weapon and target, but you cannot strike them with it at this time."
            )
        } else if possibleStrikes.count > 1 {
            throw CliParseError(
                "It seems \(contextCharacter.name) has \(possibleStrikes.count) possible strikes:\(possibleStrikes.map { "\n- \($0)" }.joined())\n\nTo specify a weapon and a target, include them in the command, like this:\n  strike longbow Shallan"
            )
        } else {
            self = possibleStrikes[0]
        }
    }

    public static var helpText: Substring { "stri(k)e [target] [weapon]" }
    public static let oneLineHelp: String? =
        "Deal full damage on a success, or partial damage if you choose to graze."
}

extension Strike: MutliParserCombatAction {
    public static func combatActionParsers(context: CliArgsConversionContext) -> [CliArgsParser<
        Strike
    >] {
        []
    }

    public static func combatActionOptions(context: CliArgsConversionContext) -> [CombatAction] {
        let possibleStrikes = Strike.possibleStrikes(
            for: context.characterRef,
            in: context.game
        )
        // TODO sort strikes by avg damage they could do
        return possibleStrikes
    }
}

extension Strike: DescribableOption {
    public func optionDescription(context: CliArgsConversionContext) -> OptionDescription {
        let description = OptionDescription(name: "\(self)")
        guard let character = context.game.characters[context.characterRef]?.core else {
            return description
        }
        guard let weapon = character.equipment[self.weaponToStrikeWith]?.core.core.asWeapon else {
            return description
        }
        let oneLineHelp =
            "\(weapon.weaponName) (\(weapon.damage)+\(character.modifiersForCoreSkills[weapon.weaponsSkill.coreSkill]) [\(weapon.weaponsSkill.coreSkill)] \(weapon.damageType)) "
            + "\(weapon.range) "
            + weapon.activeTraits(whenEquippedBy: context.characterRef, in: context.game).map { t in
                "\(t)"
            }.joined(separator: ", ")
        return OptionDescription(name: description.name, oneLineHelp: oneLineHelp)
    }
}
