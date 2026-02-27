You'll often work with families of structs or protocols, where functionality is split between a model protocol, a snapshot protocol, and a shared protocol.

An example of this is Conditions.
```swift
protocol ConditionSharedProtocol {}
protocol Condition: ConditionSharedProtocol {
    func _snapshot(in gameSession: isolated GameSession) -> any ConditionSnapshot
}
protocol ConditionSnapshot: Sendable, ConditionSharedProtocol {}
```

In some rare cases, a model type (like SurprisedCondition) only holds `Sendable` data. In those cases, we can save ourselves a little work and avoid creating a separate snapshot type by making our concrete model type also implement the snapshot protocol.

In most cases, a model type (like the AfflictedCondition) has non-Sendable data like event handlers. The swift compiler will not consider it safe to send that type to other actors, so we need to create a snapshot type (like AfflictedSnapshot).

For extremely simple model types, a dedicated type is not necessary. Instead, we can make snapshot objects using a general purpose type (like DummyConditionSnapshot) that just stores the "type" or "name" of the model type for identification purposes.