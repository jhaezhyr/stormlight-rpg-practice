import stormlight_duel

public typealias OptionDescriber<T> = @Sendable (T, GameSnapshot, RpgCharacterRef) -> String

public func optionDescriber<T>(forCode code: DecisionCode, andType _: T.Type)
    -> OptionDescriber<T>
{
    guard let untyped = describeOptionFunctionRegistry[code] else {
        return { x, y, z in "\(x)" }
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
