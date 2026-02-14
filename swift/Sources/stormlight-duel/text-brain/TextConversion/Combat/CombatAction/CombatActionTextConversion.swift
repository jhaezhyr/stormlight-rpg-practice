import stormlight_duel

extension CombatAction {
    public static var parserOpt: CliArgsParser<Self>? {
        guard let parser = Self.self as? (any CliArgsConvertibleType.Type) else {
            return nil
        }
        return CliArgsParser<Self>(helpText: parser.helpText) {
            (args, context) throws(CliParseError) in
            let result = try parser.init(args: args, context: context)
            return result.map { $0 as! Self }
        }
    }
    public static var combatChoiceParserOpt: CliArgsParser<CombatChoice>? {
        Self.parserOpt.map { x in
            CliArgsParser(parsers: [x]) { action in
                CombatChoice.action(action as! any CombatAction)
            }
        }
    }
}

struct EndTurn {}
@MainActor public let endTurnParser = CliArgsParser<CombatChoice>(helpText: "(e)nd") {
    args, context in
    if let alreadyParsedMove = args.first as? CombatChoice,
        args.count == 1,
        case .endTurn = alreadyParsedMove
    {
        return alreadyParsedMove
    }
    var remaining = args[...]
    guard
        let firstArg = remaining.popFirst(),
        let firstArgAsString = firstArg as? Substring,
        firstArgAsString == "e" || firstArgAsString == "end"
    else {
        return nil
    }
    return CombatChoice.endTurn
}
