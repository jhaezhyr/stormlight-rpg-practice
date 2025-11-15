/// A {@link WritableSignal} that exposes an interface for overwriting it's
/// internal value, signaling transitive dependents that they may need to
/// recompute their values.
public class State<T>: WritableSignal {
    private let node: StateNode<T>
    init(_ initialValue: T, _ equals: @escaping EqualsFn<T>) {
        self.node = StateNode(initialValue, equals)
    }

    /**
     * @see {@link Signal.get}
     */
    public func get() -> T {
        guard case let .value(returnValue) = self.node.value else {
            fatalError("State value should always be set")
        }
        self.node.updateWatched()
        self.node.recordAccess()
        return returnValue
    }

    /**
     * @see {@link WritableSignal.set}
     */
    public func set(_ newValue: T) {
        if self.node.setIfWouldChange(newValue) {
            self.node.valueVersion += 1
            self.node.notifyConsumers()
        }
    }

    /**
     * @see {@link WritableSignal.mutate}
     */
    public func mutate(_ mutatorFn: (_ prevValue: T) -> Void) {
        guard case .value(let currentValue) = self.node.value else {
            fatalError("State value should always be set")
        }
        mutatorFn(currentValue)
        self.node.valueVersion += 1
        self.node.notifyConsumers()
    }

    /**
     * @see {@link WritableSignal.update}
     */
    public func update(updaterFn: (_ prevValue: T) -> T) {
        guard case let .value(currentValue) = self.node.value else {
            fatalError("State value should always be set")
        }
        let newValue = updaterFn(currentValue)
        self.set(newValue)
    }
}

/// As JavaScript does not support multiple inheritance, the roles of "Producer"
/// and "Consumer" are implemented with interfaces and public values. To not
/// expose these public members to users of the Signal framework, they are
/// isolated to Node classes that are not exported.
class StateNode<T>: Producer {
    public var valueVersion = 0
    public var isWatched = false
    public var watched = [AnyConsumerRef: Int]()
    public var unwatched = [AnyConsumerWeakRef: Int]()
    public var value: ProducerValue<T>
    public let equals: EqualsFn<T>

    init(
        _ value: T,
        _ equals: @escaping EqualsFn<T>,
    ) {
        self.value = .value(value)
        self.equals = equals
    }

    public func resolveValue() -> T {
        guard case let .value(returnValue) = self.value else {
            fatalError("State value should always be set")
        }
        return returnValue
    }
}
