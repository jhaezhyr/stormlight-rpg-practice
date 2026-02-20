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
            let firstArgAsString = firstArg as? Substring,
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
        let realWeapon: ItemRef = try
            ({ (x: ()) throws(CliParseError) in
                if let weaponToStrikeWith {
                    return weaponToStrikeWith
                } else {
                    let equipment = contextCharacter.equipment
                    let viableWeapons = equipment.filter {
                        $0.isReady && $0.core.core is any WeaponSnapshot
                    }
                    if viableWeapons.count != 1 {
                        throw CliParseError(
                            "It seems \(contextCharacter.name) has \(viableWeapons.count) ready weapons: \(viableWeapons)"
                        )
                    }
                    return viableWeapons[0].primaryKey
                }
            })(())
        self.init(realTarget, with: realWeapon)
    }

    public static var helpText: Substring { "stri(k)e [target] [weapon]" }
}
