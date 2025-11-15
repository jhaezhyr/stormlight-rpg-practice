extension Consumer {
    /**
    * Determine if a any of a Consumers dependencies have actually changed.
    */
    public func anyProducersHaveChanged() -> Bool {
        for (producerRef, lastSeenVersion) in self.producers {
            let producer = producerRef.ref
            // anytime we iterate through Producers is an opportunity to clean up
            // unneeded links
            if unlinkIfNeeded(producer, self) {
                continue
            }

            if producer.valueVersion != lastSeenVersion {
                return true
            }
            /**
            * just because the valueVersion matches doesn't guarantee that a
            * Computed value hasn't changed. Recomputing that value isn't wasteful,
            * as we would need to do it anyways if we find any producers have
            * changed. (Remember also that resolved values are cached)
            */
            _ = producer.resolveValue()
            // only once we've "fetched" a dependencies value can we be sure if it
            // has changed or not
            if producer.valueVersion != lastSeenVersion {
                return true
            }
        }
        return false
    }
}

/// Determine if a "link" between a `Producer` and `Consumer` is "active" e.g.
/// if the `Producer` participated in the last evaluation of the `Consumer`.
///
/// If not, the link can be dropped to avoid wasteful or innaccurate calculation.
///
/// @returns `true` if the link was broken, else `false`
public func unlinkIfNeeded(_ producer: any Producer, _ consumer: any Consumer) -> Bool {
    let lastComputeVersion =
        producer.watched[AnyConsumerRef(consumer)]
        ?? producer.unwatched[AnyConsumerWeakRef(consumer)]
    if consumer.computeVersion == lastComputeVersion {
        return false
    }
    consumer.producers.removeValue(forKey: AnyProducerRef(producer))
    producer.watched.removeValue(forKey: AnyConsumerRef(consumer))
    producer.unwatched.removeValue(forKey: AnyConsumerWeakRef(consumer))
    return true
}

// We need these type-erased references to use as keys in dictionaries
// until Swift allows existentials to conform to their own protocols.
public struct AnyConsumerRef: Hashable {
    public let ref: any Consumer

    init(_ ref: any Consumer) {
        self.ref = ref
    }

    public static func == (lhs: AnyConsumerRef, rhs: AnyConsumerRef) -> Bool {
        return lhs.ref === rhs.ref
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(ref))
    }
}

public struct AnyConsumerWeakRef: Hashable {
    public weak var ref: (any Consumer)?
    // Once a weak ref goes dead, we still need to be able to identify what it used to point to.
    private var uniqueId: Int

    init(_ ref: any Consumer) {
        self.ref = ref
        self.uniqueId = ObjectIdentifier(ref).hashValue
    }

    public static func == (lhs: AnyConsumerWeakRef, rhs: AnyConsumerWeakRef) -> Bool {
        return lhs.uniqueId == rhs.uniqueId
    }

    public func hash(into hasher: inout Hasher) {
        // The hashing algorithm must remain stable even if the weak ref goes dead.
        hasher.combine(uniqueId)
    }
}
