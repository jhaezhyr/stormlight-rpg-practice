import stormlight_duel

public typealias ParserDescriber =
    @Sendable (any CliArgsParserProtocol, GameSnapshot, RpgCharacterRef) ->
    String
private typealias TypedParserDescriber<T> =
    @Sendable (CliArgsParser<T>, GameSnapshot, RpgCharacterRef) ->
    String

public func parserDescriber(forCode code: DecisionCode)
    -> ParserDescriber
{
    guard let untyped = parserDescriberRegistry[code] else {
        return { x, y, z in "\(x.helpText)" }
    }
    return {
        x, y, z in
        return untyped(x, y, z)
    }
}

private func generalize<T>(as _: T.Type, _ fn: @escaping TypedParserDescriber<T>) -> ParserDescriber
{
    return {
        parser, y, z in
        return fn(
            parser.map {
                x in
                guard let x = x as? T else {
                    fatalError(
                        "TypeError: Cannot describe parser for type \(type(of: x)) when it should have been a \(T.self). Value: \(x)"
                    )
                }
                return x
            }, y, z)
    }
}
private let parserDescriberRegistry: [DecisionCode: ParserDescriber] = [:]
