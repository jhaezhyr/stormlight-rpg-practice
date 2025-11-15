/// A {@link ReadonlySignal} that computes a given function and returns it's
/// output.
///
/// Produces it's value via the `get()` method, with a guarantee that it's
/// value will be up to date with changes to transitive dependencies.
public class Computed<T>: Signal {
    private let node: ComputedNode<T>
    init(_ compute: @escaping () -> T, _ equals: @escaping EqualsFn<T>) {
        self.node = ComputedNode(compute, equals)
    }

    /**
     * @see {@link Signal.get}
     */
    public func get() -> T {
        self.node.updateWatched()
        let returnValue = self.node.resolveValue()
        self.node.recordAccess()
        /**
         * Creating a Computed Signal that doesn't depend on other Signals
         * is wasteful. It would be simpler to just compute a function.
         */
        if self.node.producers.isEmpty {
            print(
                "WARNING: Computed created without any Signal dependencies note that this means the value will never be computed again.",
            )
        }
        return returnValue
    }
}

/// As Swift does not support multiple inheritance, the roles of "Producer"
/// and "Consumer" are implemented with protocols and public values. To not
/// expose these public members to users of the Signal framework, they are
/// isolated to Node classes that are not exported.
final class ComputedNode<T>: Producer, Consumer {
    public var value: ProducerValue<T>
    public var valueVersion = 0
    public var computeVersion = 0
    public var stale = true
    public var isWatched = false
    public var weakRef: WeakRef<ComputedNode<T>> {
        WeakRef(self)
    }
    public var producers = [AnyProducerRef: Int]()
    public var watched = [AnyConsumerRef: Int]()
    public var unwatched = [AnyConsumerWeakRef: Int]()
    private let compute: () -> T
    public let equals: EqualsFn<T>

    init(
        _ compute: @escaping () -> T,  // TODO make a version that throws
        _ equals: @escaping EqualsFn<T>,
    ) {
        self.compute = compute
        self.value = .unset
        self.equals = equals
    }

    public func resolveValue() -> T {
        let returnValue: T
        switch self.value {
        case .computing:
            fatalError("Signal changed while computing")
        case .unset,
            .value(_) where self.stale && self.anyProducersHaveChanged():
            self.computeVersion += 1
            let oldValue = self.value
            let newValue: T
            do {
                defer {
                    // restore value for ensuing comparison
                    self.value = oldValue
                }
                do {
                    /**
                    * This primes the condition at the top of self method
                    * to detect cycles.
                    */
                    self.value = .computing
                    newValue = try asActiveConsumer(self, self.compute)
                } catch {
                    // keep computeVersion in sync with SUCCESSFUL computation
                    self.computeVersion -= 1
                    //throw error
                }
            }
            if self.setIfWouldChange(newValue) {
                self.valueVersion += 1
            }
            returnValue = newValue
        case .value(let x):
            // The value is up to date. Do nothing.
            returnValue = x
        }
        /**
         * Regardless of what happens in self function, successful completion
         * indicates that work does not need to be repeated until a transitive
         * dependency marks self Signal as "stale" again.
         */
        self.stale = false
        return returnValue
    }

    public func invalidate() {
        if case .computing = self.value {
            fatalError("Signal changed while computing")
        }
        if self.stale {
            return
        }
        self.stale = true
        self.notifyConsumers()
    }
}
