/// A common way to compare Result values for equality, ignoring the specific errors.
///
/// If you find yourself needing this function, consider some alternatives:
///   - If the error type is Equatable, consider using `lhs == rhs` directly.
///   - If you only care about success values, consider comparing (try? lhs.get()) == (try? rhs.get())
public func areEqualIgnoringError<T: Equatable, E: Error>(
    _ lhs: Result<T, E>,
    _ rhs: Result<T, E>
) -> Bool {
    switch (lhs, rhs) {
    case (.success(let lValue), .success(let rValue)):
        return lValue == rValue
    case (.failure(_), .failure(_)):
        return true
    default:
        return false
    }
}

/// A common way to compare Result values for equality, ignoring the specific errors,
/// using reference equality for success values.
///
/// See also `areEqualIgnoringError`
public func areRefEqualIgnoringError<T: AnyObject, E: Error>(
    _ lhs: Result<T, E>,
    _ rhs: Result<T, E>
) -> Bool {
    switch (lhs, rhs) {
    case (.success(let lValue), .success(let rValue)):
        return lValue === rValue
    case (.failure(_), .failure(_)):
        return true
    default:
        return false
    }
}
