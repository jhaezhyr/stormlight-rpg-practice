/// A version of ObjectIdentifier that doesn't do type erasure
public struct Ref<T: AnyObject>: Hashable {
    public let ref: T
    init(_ ref: T) {
        self.ref = ref
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        ObjectIdentifier(lhs.ref) == ObjectIdentifier(rhs.ref)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self.ref))
    }
}

/// A version of ObjectIdentifier that doesn't do type erasure
public struct WeakRef<T: AnyObject>: Hashable {
    public weak var ref: T?
    // Once a weak ref goes dead, we still need to be able to identify what it used to point to.
    private var uniqueId: Int

    init(_ ref: T) {
        self.ref = ref
        self.uniqueId = ObjectIdentifier(ref).hashValue
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.uniqueId == rhs.uniqueId
    }

    public func hash(into hasher: inout Hasher) {
        // The hashing algorithm must remain stable even if the weak ref goes dead.
        hasher.combine(uniqueId)
    }
}
