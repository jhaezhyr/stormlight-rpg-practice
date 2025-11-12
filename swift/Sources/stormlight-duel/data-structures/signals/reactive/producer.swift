/**
 * Determines if a new value represents a meaningful change to the `Producer`'s
 * value. If so, the value is stored, and the function returns `true`,
 */
public func setIfWouldChange<T>(_ producer: any Producer, _ value: T) -> Bool where producer.T == T {
    /**
     * The Producer itself should be configured to determine what constitutes a
     * "meaningful change".
     *
     * Running the equality function without an `activeConsumer` ensures
     * that Signal dependencies aren't recorded by self function.
     */
    if let thisValue = producer.value, 
        asActiveConsumer(
            nil,
            { producer.equals(thisValue, value) },
        )
    {
        return false
    }
    producer.value = value
    return true
}

/**
 * Trigger every `Consumer` of the given `Producer` to potentially recompute on
 * the next evaluation of that `SignalNode `
 */
public func notifyConsumers(_ producer: any Producer) -> () {
    for (consumer, _) in producer.watched {
        // anytime we iterate over links is an opportunity to clean up unneeded
        // links
        !unlinkIfNeeded(producer, consumer) && consumer.invalidate()
    }

    for (weakRef, lastSeenVersion) in producer.unwatched {
        let consumer = weakRef.ref
        /**
         * In self case, not only might a link be no longer needed, it might
         * also refer to a Consumer that has been garbage collected. In either
         * case we save time and memory by cleaning up the link.
         */
        if (consumer && consumer.computeVersion == lastSeenVersion) {
            consumer.invalidate()
        } else {
            producer.unwatched.delete(weakRef)
            consumer?.producers.delete(producer)
        }
    }
}