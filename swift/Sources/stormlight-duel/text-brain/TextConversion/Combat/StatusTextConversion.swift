import stormlight_duel

public enum StatusCommand {
    case general
}
extension StatusCommand: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let alreadyParsed = args.first as? Self, args.count == 1 {
            self = alreadyParsed
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "s" || firstArgAsString == "status"
        else {
            return nil
        }
        self = .general
    }

    public static var helpText: Substring {
        "(s)tatus"
    }
}
extension StatusCommand {
    public func evaluate(in gameSnapshot: GameSnapshot, for characterRef: RpgCharacterRef) -> String
    {
        guard let combat = gameSnapshot.scene as? Combat else {
            return ""
        }
        var result = ""
        result += combat.map.oneLineDescription(in: gameSnapshot) + "\n"
        var isFirst = true
        for someCharacter in gameSnapshot.characters {
            if isFirst {
                isFirst = false
            } else {
                result += "\n"
            }
            guard let combatState = someCharacter.combatState else {
                continue
            }
            let opponents = gameSnapshot.characters.filter {
                $0.primaryKey != someCharacter.primaryKey
            }
            let (distanceToNearestOppontent, nearestOpponent) =
                opponents.map {
                    ($0.combatState?.space.distance(to: combatState.space) ?? 1000, $0)
                }
                .sorted { (lh, rh) in lh.0 < rh.0 }[0]
            let conditions = someCharacter.conditions.filter { $0.type != TempCondition.type }
            result +=
                "\(someCharacter.primaryKey == characterRef ? "You \(someCharacter.name)" : "\(someCharacter.name)"):\n"
                + "  Health: \(someCharacter.health.value)/\(someCharacter.health.maxValue)\n"
                + "  Focus: \(someCharacter.focus.value)/\(someCharacter.focus.maxValue)\n"
                + "  Actions and Reactions: \(combatState.actionsRemaining) ▶ + \(combatState.reactionsRemaining) ↻\n"
                + "  Main and Off hands: \(someCharacter.mainHand, default: "nothing"), \(someCharacter.offHand, default: "nothing")\n"
                + "  Conditions: \(conditions.map { "\($0.core)" }.joined(separator: ","))\n"
                + "  Space controlled: \(combatState.space.lo)...\(someCharacter.combatState!.space.hi)\n"
                + "  Distance to \(nearestOpponent.name): \(distanceToNearestOppontent)"
        }
        return result
    }
}
