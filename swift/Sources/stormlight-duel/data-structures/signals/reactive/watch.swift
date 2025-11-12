extension Consumer {
    /**
    * Recursively updates the watched status for a Consumer's Producers.
    *
    * Any Producers that no longer have watched Consumers are no longer watched
    * themselves.
    */
    public func unwatchProducers() {
        // avoid unnecessary recursion
        if (!self.isWatched) {
            return;
        }
        for (producer, _) in self.producers {
            // anytime we iterate through Producers is an opportunity to clean up
            // unneeded links
            if (unlinkIfNeeded(producer, self)) {
                return;
            }
            producer.unwatched[self.weakRef] = self.computeVersion;
            producer.watched.remove(self);
            // Computed Signals are both Producers and Consumers
            if let producerAsConsumer = producer as? any Consumer {
                producerAsConsumer.unwatchProducers();
            }
            // updating isWatched after recursion makes sure that the check at the
            // beginning of self function works
            if (producer.watched.size == 0) {
                producer.isWatched = false;
            }
        }
    }
}