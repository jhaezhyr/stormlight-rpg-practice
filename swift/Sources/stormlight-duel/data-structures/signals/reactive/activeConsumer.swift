/// This variable models the top of the callstack if a Producer is being
/// accessed as the result of a Consumer executing it's function, that Consumer
/// can be found on the callstack just below the Producer. By saving that
/// Consumer here before calling that function, the Producer can effectively
/// "peek" at whoever called it.
///
/// @see asActiveConsumer
nonisolated(unsafe) var activeConsumer: (any Consumer)? = nil

/// Save the previous `activeConsumer` (if any) in the callstack, and run a
/// provided function with the given `Consumer?` as the
/// `activeConsumer`.
///
/// In practice self proves useful to abstract across several different use
/// cases.
public func asActiveConsumer<T>(
    _ consumer: (any Consumer)?,
    _ fn: () throws -> T,
) rethrows -> T {
    let prev = activeConsumer
    activeConsumer = consumer
    defer {
        activeConsumer = prev
    }
    return try fn()
}

extension Producer {
    /**
    * When the activeConsumer is depended on by an Effect, all transitive
    * dependencies are moved to a watched state.
    */
    public func updateWatched() {
        guard let activeConsumer else {
            return
        }

        var producerAgain = self  // Only necessary because of language bugs
        // Producers can be consumed by a variety of Signals, but it only takes
        // 1 Consumer that is watched to move the Producer to a watched state
        producerAgain.isWatched = self.isWatched || activeConsumer.isWatched
    }

    /**
    * When an activeConsumer depends on a Signal links are established in both
    * directions for the purpose of propogating changes and recomputing sparingly.
    *
    * @see {@link notifyConsumers} and {@link anyProducersHaveChanged}
    */
    public func recordAccess() {
        guard let newActiveConsumer = activeConsumer else {
            return
        }

        newActiveConsumer.producers[self] = self.valueVersion
        let computeVersion = newActiveConsumer.computeVersion
        if self.isWatched {
            self.watched[newActiveConsumer] = computeVersion
            self.unwatched.remove(newActiveConsumer.weakRef)
        } else {
            self.unwatched[newActiveConsumer.weakRef] = computeVersion
            // deletion is not necessary, because unwatching only happens
            // (eagerly) when an Effect is disposed
        }

        activeConsumer = newActiveConsumer
    }
}
