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
        // What if the target wasn't provided?
        let targetCandidates: [RpgCharacterRef] = try
            ({ (x: ()) throws(CliParseError) in
                if let target {
                    return [target]
                } else {
                    let characters = context.game.characters
                    let viableTargets = characters.filter {
                        $0.primaryKey != contextCharacter.primaryKey && $0.health.value > 0
                    }
                    return viableTargets.map { $0.primaryKey }
                }
            })(())
        let weaponCandidates: [ItemRef] = try
            ({ (x: ()) throws(CliParseError) in
                if let weaponToStrikeWith {
                    return [weaponToStrikeWith]
                } else {
                    let equipment = contextCharacter.equipment
                    let viableWeapons = equipment.compactMap { x -> (any WeaponSnapshot)? in
                        guard x.isReady else {
                            return nil
                        }
                        return x.core.core as? any WeaponSnapshot
                    }
                    return viableWeapons.map { $0.primaryKey }
                }
            })(())
        var possibleStrikes: [Strike] = []
        for target in targetCandidates {
            for weapon in weaponCandidates {
                let possibleStrike = Strike(target, with: weapon)
                if possibleStrike.canTakeAction(by: contextCharacter.primaryKey, in: context.game) {
                    possibleStrikes.append(possibleStrike)
                }
            }
        }
        if possibleStrikes.isEmpty {
            if weaponCandidates.isEmpty {
                throw CliParseError("You have no ready weapons.")
            }
            if targetCandidates.isEmpty {
                throw CliParseError("You have no potential targets.")
            }
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
}
