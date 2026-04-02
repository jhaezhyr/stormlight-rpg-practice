import stormlight_duel

extension ShieldBashAction: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "shieldbash"
        else {
            return nil
        }
        var target: RpgCharacterRef?
        for arg in remaining {
            if let targetArg = try RpgCharacterRef(args: [arg], context: context),
                target == nil
            {
                target = targetArg
            } else {
                throw CliParseError("\(arg) not a target")
            }
        }
        let targetCandidates: [RpgCharacterRef] =
            ({ (x: ()) in
                if let target {
                    return [target]
                }
                let characters = context.game.characters
                let viableTargets = characters.filter {
                    $0.primaryKey != context.characterRef && $0.health.value > 0
                }
                return viableTargets.map { $0.primaryKey }
            })(())
        guard let realTarget = targetCandidates.first else {
            throw CliParseError("No valid target provided for shieldbash action")
        }
        self.init(opponentRef: realTarget)
    }

    public static var helpText: Substring {
        "shieldbash [target]"
    }
    public static let oneLineHelp: String? =
        "Knock an opponent prone, unless they can beat an athletics test."
}

extension ShieldBashAction: CustomStringConvertible, DescribableOption {
    public var description: String {
        "bash \(self.opponentRef)"
    }
}
