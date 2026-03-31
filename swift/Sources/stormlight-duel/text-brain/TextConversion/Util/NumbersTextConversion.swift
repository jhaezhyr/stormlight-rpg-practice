import stormlight_duel

// TODO Make distance a wrapper around a number
extension Int: CliArgsContextFreeConvertibleType {
    public init?(args: [Any]) throws(CliParseError) {
        if let alreadyParsedNumber = args.first as? Distance, args.count == 1 {
            self = alreadyParsedNumber
            return
        }
        if let string = args.first as? Substring, let int = Int(string) {
            self = int
            return
        }
        throw CliParseError("\(args) is not a number")
    }

    public static var helpText: Substring { "###" }
}

extension RandomDistribution: CustomStringConvertible {
    public var description: String {
        self.dice.map { (die, num) in "\(num)\(die)" }.joined(separator: "+")
    }
}
