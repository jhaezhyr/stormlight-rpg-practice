import stormlight_duel

public typealias ParserDescriber =
    @Sendable (any CliArgsParserProtocol, GameSnapshot, RpgCharacterRef) ->
    String

public func parserDescriber(forCode code: DecisionCode) -> ParserDescriber {
    return parserDescriberRegistry[code] ?? { x, y, z in "\(x.helpText)" }
}

private let parserDescriberRegistry: [DecisionCode: ParserDescriber] = [
    .combatChoice: combatActionParserDescriber
]
