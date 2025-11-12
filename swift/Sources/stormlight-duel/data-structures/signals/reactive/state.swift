/**
 * A {@link WritableSignal} that exposes an interface for overwriting it's
 * internal value, signaling transitive dependents that they may need to
 * recompute their values.
 */
public class State<T>: WritableSignal {
    private let node: StateNode<T>
    init(initialValue: T, equals: EqualsFn<T>) {
        self.node = StateNode(initialValue, equals)
    }

    /**
     * @see {@link Signal.get}
     */
    public func get() -> T {
        self.node.updateWatched()
        self.node.recordAccess()
        return self.node.value
    }

    /**
     * @see {@link WritableSignal.set}
     */
    public func set(_ newValue: T) -> () {
        if (self.node.setIfWouldChange(newValue)) {
            self.node.valueVersion += 1
            self.node.notifyConsumers()
        }
    }

    /**
     * @see {@link WritableSignal.mutate}
     */
    public func mutate(_ mutatorFn: (_ prevValue: T) -> ()) -> () {
        mutatorFn(self.node.value)
        self.node.valueVersion += 1
        self.node.notifyConsumers()
    }

    /**
     * @see {@link WritableSignal.update}
     */
    public func update(updaterFn: (_ prevValue: T) -> T) -> () {
        let newValue = updaterFn(self.node.value)
        self.set(newValue)
    }
}

/**
 * As JavaScript does not support multiple inheritance, the roles of "Producer"
 * and "Consumer" are implemented with interfaces and public values. To not
 * expose these public members to users of the Signal framework, they are
 * isolated to Node classes that are not exported.
 */
class StateNode<T>: Producer {
    public var valueVersion = 0
    public var isWatched = false
    public var watched = Dictionary<any Consumer, Int>()
    public var unwatched = Dictionary<WeakRef<any Consumer>, Int>()
    public var value: T
    public let equals: EqualsFn<T>

    init(
        _ value: T,
        _ equals: EqualsFn<T>,
    ) {}

    public func resolveValue() -> () {} // no-op
}