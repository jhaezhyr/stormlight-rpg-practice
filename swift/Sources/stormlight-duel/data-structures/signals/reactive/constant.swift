/// A simple wrapper around a value, for use in cases where an interface
/// wants a Signal, but there's no need for the memory overhead of an actual
/// Signal object.
public class Constant<T>: Signal {
    private let value: T
    init(_ value: T) {
        self.value = value
    }

    /**
     * @see {@link Signal.get}
     */
    public func get() -> T {
        return self.value
    }
}
