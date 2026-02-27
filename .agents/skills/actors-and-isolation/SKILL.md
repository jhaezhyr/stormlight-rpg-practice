---
name: actors-and-isolation
description: This skill helps the AI agent anticipate and solve swift compilation errors regarding actor-isolated state, Sendability, and data races.
---

# actors-and-isolation

We use actors to allow parallel processing of multiple games on the same server. This utilizes a core feature of Swift.

## Errors and how to solve them

### Actor-isolated function ... cannot be called from outside of the actor

Most of our game-logic functions are isolated to a GameSession actor object. If you are encountering this error, then maybe you have one of the following mistakes:

#### 1. Inside a test function
```swift
@Test("Martial Drill feature is present on SpearInfantry")
func testMartialDrillFeature() async throws {
    let gameSession = GameSession()
    let spearInfantry = PrefabCharacters.spearInfantry(in gameSession: gameSession) // ERROR here
    ...
}
```

**Reason for error**: The testMartialDrillFeature function isn't isolated to the gameSession actor.

**How to fix**: Wrap everything after the `gameSession` creation in a `doIt` function that is isolated to the gameSession.
```swift
@Test("Martial Drill feature is present on SpearInfantry")
func testMartialDrillFeature() async throws {
    let gameSession = GameSession()
    func doIt(in gameSession: isolated GameSession) {
        let spearInfantry = PrefabCharacters.spearInfantry(in gameSession: gameSession) // ERROR here
        ...
    }
    await doIt(in: gameSession)
}
```

### 2. Inside a nested function or closure
```swift
extension Game {
    func snapshot(in gameSession: isolated GameSession = #isolation) -> GameSnapshot {
        GameSnapshot(
            characters:
                self.characters.map {
                    $0.snapshot(in: $1) // ERROR here
                },
            ...
        )
    }
}
```

**Reason for error**: The mapping function is an anonymous closure and isn't isolated to gameSession.

Anonymous closures arguments are only isolated if the higher-order function itself is expecting an isolated function.

**How to fix**: Use an isolation-preserving higher-order function.
```swift
extension Game {
    func snapshot(in gameSession: isolated GameSession = #isolation) -> GameSnapshot {
        GameSnapshot(
            characters:
                self.characters.isolatedMap(in: gameSession) {
                    $0.snapshot(in: $1)
                },
            ...
        )
    }
}
```

