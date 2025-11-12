// Implemented based on https://github.com/jacob-church/signal

protocol SignalNode {
    var isWatched: Bool { get set } // The graph is unwatched by default
}

protocol JacobSignal: SignalNode {
    associatedtype T;
    func get() -> T;
}

typealias JacobReadOnlySignal = JacobSignal;

func jacobComputed<T, Signal: JacobSignal>(_ fn: () -> T) -> Signal where Signal.T == T {
    return JacobComputed<T>(compute: fn)
}

protocol JacobProducer: AnyObject {
    associatedtype T;
    func resolveValue();
    var consumers: [any JacobConsumer : Int] { get }
    var unwatchedConsumers: [WeakBox<any JacobConsumer> : Int] { get }
    var value: T { get }

}

protocol JacobConsumer: AnyObject {
    func invalidate();
    var producers: [any JacobProducer : Int] { get }
    var computeVersion: Int { get }
    var weakRef: WeakRef<Self>
}

class JacobState<T>: JacobProducer {
    public var consumers: any JacobConsumer
    public var valueVersion: Int = 0
    public var value: T

    get() {
        updateWatched()
    }
}


class JacobComputed<T>: JacobProducer, JacobConsumer {
    public let compute: () -> T
    var value: T? = nil;
    public var valueVersion: Int = 0
    public var computeVersion: Int = 0 // Incremented whenever we say we'll compute
    public var isWatched = false
    var weakRef = WeakRef(self)

    init(compute: @escaping () -> T) {
        self.compute = compute
    }
    
    public func get() -> T {
        self.resolveValue();
        recordAccess(producer);
        return value!;
    }

    public resolveValue() {
        if value == nil || (stale && anyProducersHaveChanged(consumer: self)) {
            newValue= 
        }
    }

    public invalidate() {
        if (stale) {
            return;
        }
        stale = true;
        notifyConsumers(self)
    }
}

func notifyConsumers(_ producer: any JacobProducer) {
    for (weakRef, lastSeenVersion) in producer.unwatchedConsumers {
        let consumer = weakRef.deref()
        if (consumer && consumer.computeVersion == lastSeenVersion) {
            consumer.invalidate()
        } else {
            producer.unwatchedConsumers.delete(weakRef)
            consumer?.producers.delete()
        }
    }
    for consumer in producer.consumers {
        !unlinkIfNeeded(consumer, producer) && consumer.invalidate();
    }
}

func recordAccess(_ producer: JacobProducer) {
    if (!activeConsumer) {
        return
    }
    activeConsumer.producers.set(producer, producer.valuVersion)
    if (activeConsumer.isWatched) {
        producer.consumers.set(activeConsumer, activeConsumer.computeVersion)
    } else {
        producer.unwatchedConsumers.set()
    }
}

var activeConsumer: JacobConsumer? = nil;
func asActiveConsumer<T>(consumer: JacobConsumer?, fn: () -> T) -> T {
    let prev = activeConsumer
    defer { activeConsumer = prev }
    return fn();
}

func setIfWouldChange(producer: JacobProducer, value: T) -> Bool {
    if (producer.value == nil || producer.value != value) {
        producer.value = value;
        return true;
    }
    return false;
}

func anyProducersHaveChanged(consumer: any JacobConsumer) -> Bool {
    for (producer, lastValueChanged) in consumer.producers {
        if (unlinkIfNeeded(consumer, producer)) {
            continue;
        }
        if (producer.valueVersion != lastSeenVersion) {
            return true;
        }
        producer.resolveValue()
        if (producer.valueVersion != lastSeenVersion) {
            return true
        }
    }
    return false
}

func unlinkIfNeeded(consumer: JacobConsumer, producer: JacobProducer) -> Bool {
    let lastSeenVersion = producer.consumers[consumer] ?? producer.unwatchedConsumers.get(consumer.weakRef);
    if (consumer.computeVersion == lastSeenVersion) {
        return false
    }
    consumer.producers.delete(producer)
    producer.consumers.delete(consumer)
    producer.unwatchedConsumers.delete(consumer.weakRef)

    if (producer.isWatched && producer.consumers.size == 0) {
        producer.isWatched = false
        isConsumer(producer: any Producer) && unwatchProducers(consumer: any Producer)
    }
    return true
}

class Effect: JacobConsumer {
    static var queue: [Effect] = []
    static func flush() {
        for effect in queue {
            effect.run()
        }
        queue = []
    }

    init(effectFn: () -> ()) {
        self.effectFn = effectFn
        Effect.queue.append(self)
    }

    let effectFn: () -> ()
    public func run() {
        if (computeVersion == 0 || anyProducersHaveChanged(self)) {
            computeVersion += 1
            asActiveConsumer(consumer: self, fn: self.effectFn)
        }

    }

    func invalidate() {
        Effect.queue.append(self)
    }

    var computeVersion: Int = 0
    var isWatched = true
    var weakRef = WeakRef(self)

    deinit {
        unwatchProducers(self)
    }
}

updateWatched(producer: JacobProducer) {
    if let activeConsumer = activeConsumer {
        producer.isWatched ||= activeConsumer.isWatched
    }
}

func unwatchProducers(consumer: any JacobConsumer) {
    for producer in consumer.producers {
        if (unlinkIfNeeded(consumer: any Consumer, producer: any Producer) || !producer.isWatched) {
            continue
        }
        producer.consumers.deelete(consumer)
        producer.unwatchedConsumers.set(consumer.weakRef, consumer.computeVersion)

        if producer.consumers.size == 0 {
            producer.isWatched = false
            if isConsumer(producer) {
                unwatchProducers(consumer: any Producer)
            }
        }
    }
}

func isConsumer(producer: JacobProducer) {

}

