/// An event with internal state that can be modified by event handlers.
public protocol CalculationEventProtocol: AnyObject, EventSync {
    associatedtype Value
    var type: CalculationEventType { get }
    var value: Value { get set }
}

/// Hint: add extensions to this type in order to add static let constants.
public struct CalculationEventType: RawRepresentable, Sendable, Hashable {
    public var rawValue: String
    public init?(rawValue: String) {
        self.rawValue = rawValue
    }
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public class CharacterPropertyCalculationEvent<Value>: CalculationEventProtocol {
    public var value: Value
    public let type: CalculationEventType
    public let characterRef: RpgCharacterRef
    public init(_ initial: Value, type: CalculationEventType, for characterRef: RpgCharacterRef) {
        self.value = initial
        self.type = type
        self.characterRef = characterRef
    }
}
