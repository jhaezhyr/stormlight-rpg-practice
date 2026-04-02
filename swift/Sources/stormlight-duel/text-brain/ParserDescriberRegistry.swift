import stormlight_duel

public typealias ParserDescriber =
    @Sendable (any CliArgsParserProtocol, GameSnapshot, RpgCharacterRef) ->
    OptionDescription

public func parserDescriber(forCode code: DecisionCode) -> ParserDescriber {
    return parserDescriberRegistry[code] ?? { x, y, z in
        OptionDescription(name: "\(x.helpText)", oneLineHelp: x.oneLineHelp)
    }
}

private let parserDescriberRegistry: [DecisionCode: ParserDescriber] = [:]
