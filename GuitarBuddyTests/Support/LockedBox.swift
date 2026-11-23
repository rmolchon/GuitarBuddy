import Foundation

/// Thread-safe mutable box for test fakes and captured state. Swift 6 forbids mutating a
/// captured `var` from `@Sendable` closures and requires `Sendable` fakes to have immutable
/// stored properties, so fakes that record calls keep that state in one of these instead.
final class LockedBox<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }

    @discardableResult
    func withValue<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.withLock { body(&storage) }
    }
}
