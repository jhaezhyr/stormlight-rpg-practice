/**
 * A version of ObjectIdentifier that doesn't do type erasure
 */
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

/**
 * A version of ObjectIdentifier that doesn't do type erasure
 */
public struct WeakRef<T: AnyObject>: Hashable { 
    public weak var ref: T?
    init(_ ref: T) {
        self.ref = ref
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        if let lh = lhs.ref, let rh = rhs.ref {
            return ObjectIdentifier(lh) == ObjectIdentifier(rh)
        } else {
            return lhs.ref == nil && rhs.ref == nil
        }
    }

    public func hash(into hasher: inout Hasher) {
        if let ref = self.ref {
            hasher.combine(ObjectIdentifier(ref))
        } else {
            hasher.combine(1)
        }
    }
}