extension Producer {
    /**
    * Determines if a new value represents a meaningful change to the `Producer`'s
    * value. If so, the value is stored, and the function returns `true`,
    */
    public func setIfWouldChange(_ value: T) -> Bool {
        /**
        * The Producer itself should be configured to determine what constitutes a
        * "meaningful change".
        *
        * Running the equality function without an `activeConsumer` ensures
        * that Signal dependencies aren't recorded by self function.
        */
        if case .value(let thisValue) = self.value,
            asActiveConsumer(
                nil,
                { self.equals(thisValue, value) },
            )
        {
            return false
        }
        self.value = .value(value)
        return true
    }

    /**
    * Trigger every `Consumer` of the given `Producer` to potentially recompute on
    * the next evaluation of that `SignalNode `
    */
    public func notifyConsumers() {
        for (consumerRef, _) in self.watched {
            let consumer = consumerRef.ref
            // anytime we iterate over links is an opportunity to clean up unneeded
            // links
            if !unlinkIfNeeded(self, consumer) {
                consumer.invalidate()
            }
        }

        for (consumerWeakRef, lastSeenVersion) in self.unwatched {
            /**
            * In self case, not only might a link be no longer needed, it might
            * also refer to a Consumer that has been garbage collected. In either
            * case we save time and memory by cleaning up the link.
            */
            if let consumer = consumerWeakRef.ref, consumer.computeVersion == lastSeenVersion {
                consumer.invalidate()
            } else {
                self.unwatched.removeValue(forKey: consumerWeakRef)
                consumerWeakRef.ref?.producers.removeValue(forKey: AnyProducerRef(self))
            }
        }
    }
}

// We need these type-erased references to use as keys in dictionaries
// until Swift allows existentials to conform to their own protocols.
public struct AnyProducerRef: Hashable {
    public let ref: any Producer

    init(_ ref: any Producer) {
        self.ref = ref
    }

    public static func == (lhs: AnyProducerRef, rhs: AnyProducerRef) -> Bool {
        return lhs.ref === rhs.ref
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(ref))
    }
}
