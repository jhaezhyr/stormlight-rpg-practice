/**
 * Recursively updates the watched status for a Consumer's Producers.
 *
 * Any Producers that no longer have watched Consumers are no longer watched
 * themselves.
 */
public func unwatchProducers(_ consumer: Consumer) {
    // avoid unnecessary recursion
    if (!consumer.isWatched) {
        return;
    }
    for (producer, _) in consumer.producers {
        // anytime we iterate through Producers is an opportunity to clean up
        // unneeded links
        if (unlinkIfNeeded(producer, consumer)) {
            return;
        }
        producer.unwatched.set(consumer.weakRef, consumer.computeVersion);
        producer.watched.delete(consumer);
        // Computed Signals are both Producers and Consumers
        if let producerAsConsumer = producer as? Consumer {
            unwatchProducers(producerAsConsumer);
        }
        // updating isWatched after recursion makes sure that the check at the
        // beginning of self function works
        if (producer.watched.size == 0) {
            producer.isWatched = false;
        }
    }
}