/**
 * A {@link ReadonlySignal} that computes a given function and returns it's
 * output.
 *
 * Produces it's value via the `get()` method, with a guarantee that it's
 * value will be up to date with changes to transitive dependencies.
 */
public class Computed<T>: ReadonlySignal<T> {
    private let node: ComputedNode<T>
    init(_ compute: @escaping () -> T, _ equals: EqualsFn<T>? = nil) {
        self.node = ComputedNode(compute, equals)
    }

    /**
     * @see {@link Signal.get}
     */
    public func get() throws -> T {
        updateWatched(self.node)
        try self.node.resolveValue()
        recordAccess(self.node)
        /**
         * Creating a Computed Signal that doesn't depend on other Signals
         * is wasteful. It would be simpler to just compute a function.
         */
        if (self.node.producers.size == 0) {
            print(
                "WARNING: Computed created without any Signal dependencies note that self means the value will never be computed again.",
            )
        }
        return self.node.value
    }
}

/**
 * As Swift does not support multiple inheritance, the roles of "Producer"
 * and "Consumer" are implemented with protocols and public values. To not
 * expose these public members to users of the Signal framework, they are
 * isolated to Node classes that are not exported.
 */
final class ComputedNode<T>: Producer, Consumer {
    enum Value {
        case value(T)
        case computing
        case unset
    }
    public var value: Value
    public var valueVersion = 0
    public var computeVersion = 0
    public var stale = true
    public var isWatched = false
    public var weakRef: WeakRef<ComputedNode<T>> {
        WeakRef(self)
    }
    public var producers = Dictionary<any Producer, Int>()
    public var watched = Dictionary<any Consumer, Int>()
    public var unwatched = Dictionary<WeakRef<Consumer>, Int>()
    private let compute: () throws -> T
    public let equals: EqualsFn<T>

    init(
        _ compute: @escaping () throws -> T,
        _ equals: EqualsFn<T>? = { (a: T, b: T) in a == b },
    ) {
        self.compute = compute
    }

    public func resolveValue() throws {
        switch self.value {
            case .computing:
                throw SignalCircularDependencyError()
            case .unset:
                fallthrough
            case .value(_) where self.stale && anyProducersHaveChanged(self):
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
                        throw error
                    }
                }
                if setIfWouldChange(self, newValue) {
                    self.valueVersion += 1
                }
            case .value(_):
                // The vlue is up to date. Do nothing.
                break
        }
        /**
         * Regardless of what happens in self function, successful completion
         * indicates that work does not need to be repeated until a transitive
         * dependency marks self Signal as "stale" again.
         */
        self.stale = false
    }

    public func invalidate() throws -> () {
        if case .computing = self.value {
            throw SignalChangedWhileComputingError()
        }
        if (self.stale) {
            return
        }
        self.stale = true
        notifyConsumers(self)
    }
}