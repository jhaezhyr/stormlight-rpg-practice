import stormlight_duel

struct CliParseError: Error {
    var description: Substring

    init(_ description: Substring) {
        self.description = description
    }
}

typealias CliArgsConversionContext = (game: GameSnapshot, characterRef: RpgCharacterRef)

/// The CLI input might look like this:
/// - move 15 back
/// - strike
protocol CliArgsConvertibleType {
    /// If it returns nil, it means it's not even trying to be this type.
    /// If it throws, it means it is trying to be this type, but it's wrong.
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError)
    static var helpText: Substring { get }
}
extension CliArgsConvertibleType {
    static var parser: CliArgsParser<Self> {
        CliArgsParser(Self.self)
    }
    static var anyParser: CliArgsParser<Any> { parser.asAny }
}

protocol CliArgsParserProtocol {
    associatedtype Value
    var helpText: Substring { get }
    func parse(args: [Any], context: CliArgsConversionContext) throws(CliParseError) -> Value?
}
struct CliArgsParser<T>: CliArgsParserProtocol {
    let helpText: Substring
    let parseFunc: (_ args: [Any], _ context: CliArgsConversionContext) throws(CliParseError) -> T?
    func parse(args: [Any], context: CliArgsConversionContext) throws(CliParseError) -> T? {
        let result = try parseFunc(args, context)
        return result
    }
}
extension CliArgsParser where T: CliArgsConvertibleType {
    init(_ type: T.Type) {
        self.helpText = type.helpText
        self.parseFunc = type.init(args:context:)
    }
}
extension CliArgsParser {
    init(parsers: [any CliArgsParserProtocol], converter: @escaping (Any) -> T?) {
        self.parseFunc = { (args, context) throws(CliParseError) in
            for parser in parsers {
                if let result = try parser.parse(args: args, context: context),
                    let convertedResult = converter(result)
                {
                    return convertedResult
                }
            }
            return nil
        }
        self.helpText = parsers.map { $0.helpText }.joined(separator: "\n")[...]
    }
}
extension CliArgsParser {
    var asAny: CliArgsParser<Any> {
        CliArgsParser<Any>(helpText: self.helpText) { (args, context) throws(CliParseError) in
            try parseFunc(args, context)
        }
    }
}

protocol CliArgsContextFreeConvertibleType: CliArgsConvertibleType {
    init?(args: [Any]) throws(CliParseError)
}
extension CliArgsContextFreeConvertibleType {
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        try self.init(args: args)
    }
}
