import stormlight_duel

public struct OptionDescription {
    var name: String
    var oneLineHelp: String? = nil
}
extension OptionDescription: CustomStringConvertible {
    public var description: String {
        name + (oneLineHelp.map { "\n  ? " + $0 } ?? "")
    }
}

public typealias OptionDescriber<T> =
    @Sendable (T, GameSnapshot, RpgCharacterRef) -> OptionDescription

public func optionDescriber<T>(forCode code: DecisionCode, andType _: T.Type)
    -> OptionDescriber<T>
{
    guard let untyped = describeOptionFunctionRegistry[code] else {
        return { x, y, z in
            if let describableOption = x as? DescribableOption {
                return describableOption.optionDescription(context: (y, z))
            }
            return OptionDescription(name: "\(x)", oneLineHelp: nil)
        }
    }
    return {
        x, y, z in
        return untyped(x as T, y, z)
    }
}

private func generalize<T>(_ fn: @escaping OptionDescriber<T>) -> OptionDescriber<Any> {
    return {
        x, y, z in
        guard let x = x as? T else {
            fatalError(
                "TypeError: Cannot describe option of type \(type(of: x)) when it should have been a \(T.self). Value: \(x)"
            )
        }
        return fn(x, y, z)
    }
}
private let describeOptionFunctionRegistry: [DecisionCode: OptionDescriber<Any>] = [
    .skillForGainAdvantage: generalize(skillForGainAdvantageOptionDescriber),
    .initiative: generalize(initiativeOptionDescriber),
    .shouldGraze: generalize(grazeOptionDescriber),
]
