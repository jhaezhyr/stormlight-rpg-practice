import stormlight_duel

enum StatusCommand {
    case general
}
extension StatusCommand: CliArgsConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
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

    static var helpText: Substring {
        "(s)tatus"
    }
}
extension StatusCommand {
    func evaluate(in gameSnapshot: GameSnapshot, for characterRef: RpgCharacterRef) -> String {
        guard let character = gameSnapshot.characters[characterRef]?.core else {
            return "WHO ARE YOU?"
        }
        var result = ""
        result += (gameSnapshot.scene as! Combat).map.oneLineDescription(in: gameSnapshot) + "\n"
        var isFirst = true
        for someCharacter in gameSnapshot.characters {
            if isFirst {
                isFirst = false
            } else {
                result += "\n"
            }
            let opponents = gameSnapshot.characters.filter {
                $0.primaryKey != someCharacter.primaryKey
            }
            let (distanceToNearestOppontent, nearestOpponent) =
                opponents.map {
                    ($0.combatState!.space.distance(to: someCharacter.combatState!.space), $0)
                }
                .sorted { (lh, rh) in lh.0 < rh.0 }[0]
            result +=
                "\(someCharacter.primaryKey == characterRef ? "Your" : "\(someCharacter.name)'s") stats:\n"
                + "  Health: \(someCharacter.health.value)/\(character.health.maxValue)\n"
                + "  Focus: \(someCharacter.focus.value)/\(character.focus.maxValue)\n"
                + "  Conditions: \(someCharacter.conditions.map { "\($0.core)" }.joined(separator: ","))\n"
                + "  Space controlled: \(someCharacter.combatState!.space.lo)...\(someCharacter.combatState!.space.hi)\n"
                + "  Distance to \(nearestOpponent.name): \(distanceToNearestOppontent)"
        }
        return result
    }
}
