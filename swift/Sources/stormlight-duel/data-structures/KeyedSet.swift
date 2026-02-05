public protocol Keyed {
    associatedtype Key: Hashable, Sendable
    var primaryKey: Key { get }
}

public struct KeyedSet<Element: Keyed> {
    public typealias Key = Element.Key
    private var core: [Key: Element]
    public init<C: Collection>(_ core: C) where C.Element == Element {
        self.core = Dictionary(uniqueKeysWithValues: core.map { ($0.primaryKey, $0) })
    }

    public subscript(_ key: Key) -> Element? {
        get { core[key] }
        set {
            if let newValue {
                let oldKey = core[key]?.primaryKey
                assert(newValue.primaryKey == oldKey)
                core[key] = newValue
            } else {
                _ = remove(key)
            }
        }
    }
    public subscript(_ key: Key, default defaultValue: Element) -> Element {
        get { core[key, default: defaultValue] }
        set {
            let oldKey = core[key, default: defaultValue].primaryKey
            assert(newValue.primaryKey == oldKey)
            core[key, default: defaultValue] = newValue
        }
    }

    public var keys: [Key: Element].Keys {
        core.keys
    }

    @discardableResult
    public mutating func upsert(_ x: Element) -> Index {
        core[x.primaryKey] = x
        return core.index(forKey: x.primaryKey)!
    }
    @discardableResult
    public mutating func remove(_ x: Element) -> Element? {
        core.removeValue(forKey: x.primaryKey)
    }
    @discardableResult
    public mutating func remove(_ key: Key) -> Element? {
        core.removeValue(forKey: key)
    }
    public func contains(_ key: Key) -> Bool {
        core[key] != nil
    }
    public func contains(_ x: Element) -> Bool {
        core[x.primaryKey] != nil
    }
}

extension KeyedSet: Collection {
    public typealias Index = [Key: Element].Index

    public subscript(position: [Key: Element].Index) -> Element {
        get { core[position].1 }
    }
    public var startIndex: Dictionary<Key, Element>.Index {
        core.startIndex
    }
    public var endIndex: Dictionary<Key, Element>.Index {
        core.endIndex
    }
    public func index(after i: Dictionary<Key, Element>.Index) -> Dictionary<Key, Element>.Index {
        core.index(after: i)
    }
}

extension KeyedSet: Sendable where Element: Sendable {
}
extension KeyedSet: Equatable where Element: Equatable {
    public static func == (lh: Self, rh: Self) -> Bool {
        lh.core == rh.core
    }
}

extension KeyedSet: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}
