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

/// Multi-parser combat actions

public protocol MutliParserCombatAction: CombatAction {
    static func combatActionParsers(context: CliArgsConversionContext) -> [CliArgsParser<Self>]
}
extension MutliParserCombatAction where Self: CliArgsConvertibleType {
    public static func combatActionParsers(context: CliArgsConversionContext) -> [CliArgsParser<
        Self
    >] {
        [parser]
    }
}
extension MutliParserCombatAction {
    public static func combatChoiceParsers(context: CliArgsConversionContext)
        -> [CliArgsParser<CombatChoice>]
    {
        combatActionParsers(context: context).map { p in p.map { t in CombatChoice.action(t) } }
    }
}
extension CombatAction {
    public static func combatChoiceParsers(context: CliArgsConversionContext)
        -> [CliArgsParser<CombatChoice>]?
    {
        if let registeredGetter = MutliParserCombatAction_registry["\(Self.self)"] {
            return registeredGetter(context)
        }
        return nil
    }
}
private let MutliParserCombatAction_registry:
    [CombatActionName: @Sendable (CliArgsConversionContext) -> [CliArgsParser<CombatChoice>]] = [
        "\(Strike.self)": Strike.combatChoiceParsers(context:)
    ]

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
        let firstArgAsString = (firstArg as? Substring)?.lowercased(),
        firstArgAsString == "e" || firstArgAsString == "end"
    else {
        return nil
    }
    return CombatChoice.endTurn
}

public func combatActionParserDescriber(
    parser: any CliArgsParserProtocol, snapshot: GameSnapshot, characterRef: RpgCharacterRef
) -> String {
    guard let character = snapshot.characters[characterRef] else {
        fatalError("Character missing")
    }
    return switch parser.valueTypeId {
    case "\(Strike.self)":
        "\(parser.helpText)\n  ? \(Strike.oneLineHelp)"
    case "\(GainAdvantage.self)":
        "\(parser.helpText)\n  ? \(GainAdvantage.oneLineHelp)"
    case "\(InteractiveDrawWeapons.self)":
        "\(parser.helpText)\n  ? \(InteractiveDrawWeapons.oneLineHelp)"
    case "\(InteractiveRecover.self)":
        "\(parser.helpText)\n  ? \(InteractiveRecover.oneLineHelp(character))"
    case "\(InteractiveDrawWeapons.self)":
        "\(parser.helpText)\n  ? \(InteractiveMove.oneLineHelp(character))"
    default:
        "\(parser.helpText)"
    }
    // TODO Actually, the parser is always returning "CombatChoice"s. Whoops.
}
private let d: ParserDescriber = combatActionParserDescriber
