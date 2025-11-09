struct CompleteDictionary<Key: Hashable & CaseIterable & Sendable, Value: Sendable>: Sendable {
    private var core: [Key: Value]
    public init(from dictionary: Dictionary<Key, Value>) {
        core = dictionary
        var missingCases = [Key]()
        for key in Key.allCases {
            guard let _ = core[key] else {
                missingCases.append(key)
                continue
            }
        }
        if !missingCases.isEmpty {
            fatalError("CompleteDictionary incomplete. Missing keys: \(missingCases)")
        }
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
    typealias Element = (Key, Value)
    typealias Index = [Key: Value].Index
    var startIndex: Dictionary<Key, Value>.Index {
        core.startIndex
    }
    var endIndex: Dictionary<Key, Value>.Index {
        core.endIndex
    }

    func index(after i: Dictionary<Key, Value>.Index) -> Dictionary<Key, Value>.Index {
        return core.index(after: i)
    }

    subscript(position: Dictionary<Key, Value>.Index) -> (Key, Value) {
        get {
            return core[position]
        }
    }
}

extension CompleteDictionary: ExpressibleByDictionaryLiteral {
    init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(from: Dictionary(uniqueKeysWithValues: elements))
    }
}
