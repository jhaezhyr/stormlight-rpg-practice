public struct CompleteDictionary<Key: Hashable & CaseIterable & Sendable, Value: Sendable>: Sendable
{
    private var core: [Key: Value]
    public init(from dictionary: [Key: Value]) {
        core = dictionary
        var missingCases = [Key]()
        for key in Key.allCases {
            guard core[key] != nil else {
                missingCases.append(key)
                continue
            }
        }
        if !missingCases.isEmpty {
            fatalError("CompleteDictionary incomplete. Missing keys: \(missingCases)")
        }
    }
    public init(valueFn: (_ k: Key) -> Value) {
        core = Dictionary(uniqueKeysWithValues: Key.allCases.map { ($0, valueFn($0)) })
    }
    public subscript(key: Key) -> Value {
        get {
            return core[key]!
        }
        set {
            core[key] = newValue
        }
    }
}

extension CompleteDictionary: Collection {
    public typealias Element = (Key, Value)
    public typealias Index = [Key: Value].Index
    public var startIndex: Dictionary<Key, Value>.Index {
        core.startIndex
    }
    public var endIndex: Dictionary<Key, Value>.Index {
        core.endIndex
    }

    public func index(after i: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Index {
        return core.index(after: i)
    }

    public subscript(position: Dictionary<Key, Value>.Index) -> (Key, Value) {
        get {
            return core[position]
        }
    }

    public func mapValues<T: Sendable>(transform: (_ value: Value) -> T) -> CompleteDictionary<
        Key, T
    > {
        CompleteDictionary<Key, T>(from: core.mapValues(transform))
    }

    public func mapLabeledValues<T: Sendable>(transform: (_ key: Key, _ value: Value) -> T)
        -> CompleteDictionary<Key, T>
    {
        CompleteDictionary<Key, T>(
            from: Dictionary(
                uniqueKeysWithValues: core.map({ key, value in (key, transform(key, value)) })))
    }
}

extension CompleteDictionary: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(from: Dictionary(uniqueKeysWithValues: elements))
    }
}

extension Dictionary {
    public func mapLabeledValues<T: Sendable>(transform: (_ key: Key, _ value: Value) -> T) -> [Key:
        T]
    {
        [Key: T](uniqueKeysWithValues: self.map({ key, value in (key, transform(key, value)) }))
    }
}
