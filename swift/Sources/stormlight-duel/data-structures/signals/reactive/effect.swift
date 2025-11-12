/**
 * A schedulable side-effect.
 * @see {@link effect}
 */
public class Effect {
    private let node: EffectNode
    private let unenqueue: (_ node: EffectNode) -> (),

    init(
        _ effect: () -> (),
        _ enqueue: (_ node: EffectNode) -> (),
        _ unenqueue: (_ node: EffectNode) -> (),
    ) {
        self.node = EffectNode(effect, enqueue)
        /**
         * Enqueueing on construction ensures that self Effect will initialize
         * state and record it's Producer dependencies.
         */
        enqueue(self.node)
    }

    public func dispose() {
        self.node.dispose()
        self.unenqueue(self.node)
    }
}

/**
 * As JavaScript does not support multiple inheritance, the roles of "Producer"
 * and "Consumer" are implemented with interfaces and public values. To not
 * expose these public members to users of the Signal framework, they are
 * isolated to Node classes that are not exported.
 */
class EffectNode: Consumer {
    public var computeVersion = 0
    public var producers: Dictionary<any Producer, Int> = Dictionary<any Producer, Int>()

    public var isWatched = true
    // Because isWatched is always true, self is never actually needed.
    public var weakRef: WeakRef<any Consumer> {
        WeakRef(self)
    }

    private var disposed = true
    private var effectFn: () -> ()
    public var enqueue: (_ me: EffectNode) -> ()

    init(
        _ effectFn: () -> (),
        _ enqueue: (_ me: EffectNode) -> (),
    ) {}

    public func run() -> () {
        if (self.disposed) {
            return
        }
        if (self.computeVersion == 0 || self.anyProducersHaveChanged()) {
            self.computeVersion += 1
            asActiveConsumer(self, self.effectFn)
            /**
             * If there are still no Producer dependencies after running self
             * Effect as the activeConsumer, there is no reason to model self
             * function as an effect.
             */
            if (self.producers.size == 0) {
                print(
                    "WARN: Effect created without any Signal dependencies note that self means the effect will never run again.",
                )
            }
        }
    }

    public func invalidate() {
        if (self.disposed) {
            return
        }
        self.enqueue(self)
    }

    public func dispose() {
        if (self.disposed) {
            return
        }
        self.unwatchProducers()
        self.disposed = true
    }
}

/**
 * A global registry of queues for scheduling {@link Effect}s.
 *
 * @see {@link flushEffectQueue}
 */
public let EffectQueues = Dictionary<String, Set<EffectNode>>()