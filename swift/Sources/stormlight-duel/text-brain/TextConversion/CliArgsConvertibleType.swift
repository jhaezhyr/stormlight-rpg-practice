import stormlight_duel

public struct CliParseError: Error {
    public var description: Substring

    public init(_ description: Substring) {
        self.description = description
    }
}

public typealias CliArgsConversionContext = (game: GameSnapshot, characterRef: RpgCharacterRef)

/// The CLI input might look like this:
/// - move 15 back
/// - strike
public protocol CliArgsConvertibleType {
    /// If it returns nil, it means it's not even trying to be this type.
    /// If it throws, it means it is trying to be this type, but it's wrong.
    init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError)
    static var helpText: Substring { get }
    static var oneLineHelp: String? { get }
}
extension CliArgsConvertibleType {
    public static var parser: CliArgsParser<Self> {
        CliArgsParser(Self.self)
    }
    public static var anyParser: CliArgsParser<Any> { parser.asAny }
    public static var oneLineHelp: String? { nil }
    public static var optionDescription: OptionDescription {
        .init(name: "\(helpText)", oneLineHelp: oneLineHelp)
    }
}

public protocol CliArgsParserProtocol {
    associatedtype Value
    var valueTypeId: String { get }
    var helpText: Substring { get }
    var oneLineHelp: String? { get }
    func parse(args: [Any], context: CliArgsConversionContext) throws(CliParseError) -> Value?
    func map<U>(_ mapFn: @escaping (Value) -> U) -> CliArgsParser<U>
}
public struct CliArgsParser<T>: CliArgsParserProtocol {
    public let helpText: Substring
    public let oneLineHelp: String?
    public var valueTypeId: String { "\(T.self)" }
    private let parseFunc:
        (_ args: [Any], _ context: CliArgsConversionContext) throws(CliParseError) -> T?
    public func parse(args: [Any], context: CliArgsConversionContext) throws(CliParseError) -> T? {
        let result = try parseFunc(args, context)
        return result
    }
    public init(
        helpText: Substring,
        oneLineHelp: String? = nil,
        parseFunc:
            @escaping (_ args: [Any], _ context: CliArgsConversionContext) throws(CliParseError) ->
            T?
    ) {
        self.helpText = helpText
        self.oneLineHelp = oneLineHelp
        self.parseFunc = parseFunc
    }
    public func map<U>(_ mapFn: @escaping (T) -> U) -> CliArgsParser<U> {
        CliArgsParser<U>(helpText: self.helpText) {
            (x, y) throws(CliParseError) in
            try self.parse(args: x, context: y).map { parsedAsT in mapFn(parsedAsT) }
        }
    }
}
extension CliArgsParser where T: CliArgsConvertibleType {
    public init(_ type: T.Type) {
        self.helpText = type.helpText
        self.parseFunc = type.init(args:context:)
        self.oneLineHelp = type.oneLineHelp
    }
}
extension CliArgsParser {
    public init(parsers: [any CliArgsParserProtocol], converter: @escaping (Any) -> T?) {
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
        self.oneLineHelp = parsers.compactMap { $0.oneLineHelp }.joined(separator: "\n")
    }
}
extension CliArgsParser {
    public var asAny: CliArgsParser<Any> {
        CliArgsParser<Any>(helpText: self.helpText) { (args, context) throws(CliParseError) in
            try parseFunc(args, context)
        }
    }
}

public protocol CliArgsContextFreeConvertibleType: CliArgsConvertibleType {
    init?(args: [Any]) throws(CliParseError)
}
extension CliArgsContextFreeConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        try self.init(args: args)
    }
}
