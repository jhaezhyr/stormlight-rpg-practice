////////////////////////////////////////////////////////////////////////////////
// Signal Types

/// A reactive wrapper around a value.
public protocol Signal {
    associatedtype T
    /** unwraps the inner value held by a `Signal` */
    func get() throws -> T
}

/// A `Signal` that supports only the readonly `get()` operation.
public typealias ReadonlySignal<T> = Computed<T>
//public typealias ReadonlySignal<A> = Signal where Self.T == A

/// A `Signal` with a setter and mutator methods.
public protocol WritableSignal: Signal {
    /**
     * Guarantees that the inner value will match the provided `value`, and
     * any dependent Signals will be notified of the change (if necessary).
     */
    func set(_ value: T)
    /**
     * Exposes the inner value to a provided function, allowing in-place
     * manipulation (e.g. for inner values that are data structures).
     *
     * Guarantees that dependent Signals will be notified, and may recompute
     * on their next access.
     */
    func mutate(_ mutatorFn: (_ prevValue: T) -> Void)
    /**
     * Exposes the inner value in a readonly state to the provided function,
     * allowing for the computation of a new value based on it's previous value.
     *
     * If the new value is meaningfully changed, dependent Signals will be
     * notified, and may recompute on their next access.
     */
    func update(updaterFn: (_ prevValue: T) -> T)
}

////////////////////////////////////////////////////////////////////////////////
// Signal Node Types
public protocol SignalNode {
    /**
     * whether or not a Signal is an Effect or transitive dependency of one
     */
    var isWatched: Bool { get set }
}

/// `Signal`s that are depended on by other `Signal`s "Produce" values to their
/// dependents.
public protocol Producer: AnyObject, SignalNode {
    associatedtype T

    /**
     * The inner data cache that a `Producer` provides to it's `Consumer`s
     */
    var value: ProducerValue<T> { get set }
    /**
     * A monotonically increasing Int that only increments when the value
     * changes available for cheap comparison to track which `Producer`s are
     * up to date, or need to be recomputed.
     */
    var valueVersion: Int { get }
    /**
     * The set of `Consumer`s of self `Producer` that are in a "watched" state.
     * @see SignalNode.isWatched
     * A mapping from `Consumer` to the last observed
     * {@link Consumer.computeVersion}, indicating whether self `Producer`
     * participated in the last recompute, or if the link needs to be cleaned up.
     */
    var watched: [AnyConsumerRef: Int] { get set }
    /**
     * As `watched` above, but for `Consumer`s that are in an unwatched state.
     */
    var unwatched: [AnyConsumerWeakRef: Int] { get set }
    /**
     * The notion of equality between potential `Signal` values of the same type.
     *
     * Used to prevent unneccessary updates to `valueVersion`, and unnecessary
     * calls to {@link notifyConsumers}
     */
    var equals: (_ a: T, _ b: T) -> Bool { get }
    /**
     * A function to be called to guarantee that the inner `value` of self
     * `Producer` is settled and up to date with it's own transitive
     * dependencies. Also guarantees that `valueVersion` is up to date.
     */
    func resolveValue() throws -> T
}

public enum ProducerValue<T> {
    case value(T)
    case computing
    case unset
}

public protocol Consumer: AnyObject, SignalNode {
    /**
     * A monotonically increasing Int that only increments when a `Consumer`
     * fully re-evaluates (e.g. a `Computed` runs it's compute function, or an
     * `Effect` runs it's effect function) used to track which `Producer`s are
     * no longer needed dependencies
     */
    var computeVersion: Int { get }
    /**
     * Mapping from `Producer` dependency to the last {@link Producer.valueVersion}
     * that was accessed by self `Consumer` used by
     * {@link anyProducersHaveChanged} to short-circuit recomputations
     */
    var producers: [AnyProducerRef: Int] { get set }
    /**
     * Used to track {@link Producer.unwatched} `Consumer`s without preventing
     * the `Consumer` from being garbage collected.
     */
    var weakRef: WeakRef<Self> { get }
    /**
     * every Consumer has a notion of being marked for future re-evaluation
     */
    func invalidate() throws
}

////////////////////////////////////////////////////////////////////////////////

public typealias EqualsFn<T> = (_ a: T, _ b: T) -> Bool
