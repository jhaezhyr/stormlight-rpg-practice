import stormlight_duel

extension CombatAction {
    public static func parserOpt(context: CliArgsConversionContext) -> CliArgsParser<Self>? {
        guard let parser = Self.self as? (any CliArgsConvertibleType.Type) else {
            return nil
        }
        return CliArgsParser<Self>(
            helpText: "[\(Self.maybeCostDescription(context: context))] \(parser.helpText)",
            oneLineHelp: parser.oneLineHelp
        ) {
            (args, context) throws(CliParseError) in
            let result = try parser.init(args: args, context: context)
            return result.map { $0 as! Self }
        }
    }
    public static func combatChoiceParserOpt(context: CliArgsConversionContext) -> CliArgsParser<
        CombatChoice
    >? {
        Self.parserOpt(context: context).map { x in
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

// DescribableOption

public protocol DescribableOption {
    func optionDescription(context: CliArgsConversionContext) -> OptionDescription
}
extension DescribableOption where Self: CliArgsConvertibleType {
    public func optionDescription(context: CliArgsConversionContext) -> OptionDescription {
        OptionDescription(name: "\(self)", oneLineHelp: Self.oneLineHelp)
    }
}

extension CombatChoice: DescribableOption {
    public func optionDescription(context: CliArgsConversionContext) -> OptionDescription {
        switch self {
        case .action(let action):
            let initialDescription: OptionDescription
            if let describableOption = action as? DescribableOption {
                initialDescription = describableOption.optionDescription(context: context)
            } else {
                initialDescription = OptionDescription(name: "\(action)")
            }
            return OptionDescription(
                name: "[\(action.costDescription(context: context))] \(initialDescription.name)",
                oneLineHelp: initialDescription.oneLineHelp)
        case .endTurn:
            return EndTurn.optionDescription
        }
    }
}

// End Turn

struct EndTurn: CliArgsContextFreeConvertibleType {
    public static let helpText: Substring = "(e)nd"
    public init() {}
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedMove = args.first as? EndTurn,
            args.count == 1
        {
            self = alreadyParsedMove
            return
        }
        var remaining = args[...]
        guard
            let firstArg = remaining.popFirst(),
            let firstArgAsString = (firstArg as? Substring)?.lowercased(),
            firstArgAsString == "e" || firstArgAsString == "end"
        else {
            return nil
        }
    }
}

extension CombatAction {
    public func costDescription(context: CliArgsConversionContext) -> String {
        let actionCost = self.actionCost(by: context.characterRef, in: context.game)
        let actionChunk = "\(actionCost)▶"
        let reactionCost = self.reactionCost(by: context.characterRef, in: context.game)
        let reactionChunk = reactionCost > 0 ? "\(reactionCost)↻" : ""
        let focusCost = self.focusCost(by: context.characterRef, in: context.game)
        let focusChunk = focusCost > 0 ? "\(focusCost)♦︎" : ""
        let costChunk = [actionChunk, reactionChunk, focusChunk].filter { !$0.isEmpty }.joined(
            separator: " ")
        return costChunk
    }
    public static func maybeCostDescription(context: CliArgsConversionContext) -> String {
        let actionCost = self.actionCost(by: context.characterRef, in: context.game)
        let actionChunk = "\(actionCost)▶"
        let reactionCost = self.reactionCost(by: context.characterRef, in: context.game)
        let reactionChunk = reactionCost > 0 ? "\(reactionCost)↻" : ""
        let focusCost = self.focusCost(by: context.characterRef, in: context.game)
        let focusChunk = focusCost > 0 ? "\(focusCost)♦︎" : ""
        let costChunk = [actionChunk, reactionChunk, focusChunk].filter { !$0.isEmpty }.joined(
            separator: " ")
        return costChunk
    }
}
