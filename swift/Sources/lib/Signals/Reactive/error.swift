public struct SignalCircularDependencyError: Error {
    let message = "Cycle detected in Signal graph."
}

public struct SignalChangedWhileComputingError: Error {
    let message = "A WritableSignal was updated while self Signal was computing."
}
