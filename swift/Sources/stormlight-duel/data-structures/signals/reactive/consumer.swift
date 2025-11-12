/**
 * Determine if a any of a Consumers dependencies have actually changed.
 */
public func anyProducersHaveChanged(_ consumer: any Consumer) -> Bool {
    for (producer, lastSeenVersion) in consumer.producers {
        // anytime we iterate through Producers is an opportunity to clean up
        // unneeded links
        if (unlinkIfNeeded(producer, consumer)) {
            continue
        }

        if (producer.valueVersion != lastSeenVersion) {
            return true
        }
        /**
         * just because the valueVersion matches doesn't guarantee that a
         * Computed value hasn't changed. Recomputing that value isn't wasteful,
         * as we would need to do it anyways if we find any producers have
         * changed. (Remember also that resolved values are cached)
         */
        producer.resolveValue()
        // only once we've "fetched" a dependencies value can we be sure if it
        // has changed or not
        if (producer.valueVersion != lastSeenVersion) {
            return true
        }
    }
    return false
}

/**
 * Determine if a "link" between a `Producer` and `Consumer` is "active" e.g.
 * if the `Producer` participated in the last evaluation of the `Consumer`.
 *
 * If not, the link can be dropped to avoid wasteful or innaccurate calculation.
 *
 * @returns `true` if the link was broken, else `false`
 */
public func unlinkIfNeeded(_ producer: any Producer, _ consumer: any Consumer) -> Bool {
    let lastComputeVersion = producer.watched[consumer] ??
        producer.unwatched[consumer.weakRef]
    if (consumer.computeVersion == lastComputeVersion) {
        return false
    }
    consumer.producers.delete(producer)
    producer.watched.delete(consumer)
    producer.unwatched.delete(consumer.weakRef)
    return true
}