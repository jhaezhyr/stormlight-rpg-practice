import Signals
import Testing

// Huge issue. Signals are not Sendable, and therefore not thread-safe. They rely on activeConsumer internally, which is a global context variable. It could be made @TaskLocal, but that only solves half the issue. The other half is that no Task is gauranteed to stay on the same thread forever, so Signals themselves need to become Sendable.
// In order to run all these tests concurrently and have them not fail, you'd have to remove all the nonisolated(unsafe) annotations in the Signals target.

@Test("make sure signals work right")
func testSignals() async throws {
    let a = state(1)
    let b = state(2)
    let sum = computed { a.get() + b.get() }

    #expect(sum.get() == 3)

    a.set(3)
    #expect(sum.get() == 5)
}

@Test("print all the calculations")
func testSignalsWithCalculations() async throws {
    var numCalculations = 0

    let a = state(1)
    let b = state(2)
    let sum = computed {
        numCalculations += 1
        return a.get() + b.get()
    }

    #expect(numCalculations == 0)
    #expect(sum.get() == 3)
    #expect(numCalculations == 1)
    #expect(sum.get() == 3)
    #expect(numCalculations == 1)

    a.set(3)
    #expect(numCalculations == 1)
    #expect(sum.get() == 5)
    #expect(numCalculations == 2)
}

@Test("effects run when signals change")
func testEffectsRunOnSignalChange() async throws {
    var effectsToKeepAlive = [Effect]()
    func observe<T: Signal>(_ sig: T, onChange: @escaping () -> Void) -> T {
        effectsToKeepAlive.append(
            effect {
                _ = sig.get()
                onChange()
            })
        return sig
    }
    var aChanges = 0
    let a = observe(state(1)) { aChanges += 1 }
    var bChanges = 0
    let b = observe(state(2)) { bChanges += 1 }
    var sumChanges = 0
    let sum = observe(computed { a.get() + b.get() }) { sumChanges += 1 }
    #expect(aChanges == 0)
    #expect(bChanges == 0)
    #expect(sumChanges == 0)
    flushEffectQueue()
    #expect(aChanges == 1)
    #expect(bChanges == 1)
    #expect(sumChanges == 1)
    flushEffectQueue()
    #expect(aChanges == 1)
    #expect(bChanges == 1)
    #expect(sumChanges == 1)
    a.set(3)
    flushEffectQueue()
    #expect(aChanges == 2)
    #expect(bChanges == 1)
    #expect(sumChanges == 2)
    b.set(4)
    flushEffectQueue()
    #expect(aChanges == 2)
    #expect(bChanges == 2)
    #expect(sumChanges == 3)
    #expect(sum.get() == 7)
    effectsToKeepAlive = []
}

@Test("signals are ergonomic even when calculations can fail")
func testSignalsWithFailingCalculations() async throws {
    enum TestError: Error, Equatable {
        case intentionalFailure
    }

    let a = state(1)
    let b = state(0)
    let division = computed(
        {
            Result {
                let divisor = b.get()
                if divisor == 0 {
                    throw TestError.intentionalFailure
                }
                return a.get() / divisor
            }
        }, areEqualSuccessesOrBothFailures)

    #expect((try? division.get().get()) == nil)

    b.set(2)
    #expect((try? division.get().get()) == 0)

    a.set(5)
    #expect((try? division.get().get()) == 2)

    b.set(0)
    #expect((try? division.get().get()) == nil)
}
