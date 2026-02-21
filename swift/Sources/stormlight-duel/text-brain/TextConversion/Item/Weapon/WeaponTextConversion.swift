import stormlight_duel

extension WeaponName: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedName = args.first as? WeaponName, args.count == 1 {
            self = alreadyParsedName
            return
        }
        if let string = args.first as? Substring,
            let weaponName = WeaponName(caseInsensitiveRawValue: String(string))
        {
            self = weaponName
            return
        }
        throw CliParseError("\(args) is not a weapon name")
    }
    public static var helpText: Substring { "<weapon>" }
}

extension BasicWeapon: CustomStringConvertible {
    public var description: String {
        "\(weaponName)"
    }
}
