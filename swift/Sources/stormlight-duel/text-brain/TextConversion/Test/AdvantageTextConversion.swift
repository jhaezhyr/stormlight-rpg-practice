import stormlight_duel

extension DecideOrOther: CliArgsConvertibleType where T: CliArgsConvertibleType {
    public init?(args: [Any], context: CliArgsConversionContext) throws(CliParseError) {
        if let result = try T.init(args: args, context: context) {
            self = .decide(result)
        } else {
            self = .other(args.map { "\($0)" }.joined(separator: " "))
        }
    }

    public static var helpText: Substring {
        T.helpText
    }
}
