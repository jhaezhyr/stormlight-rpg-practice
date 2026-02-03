public enum NumberDie: Int, Sendable {
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d12 = 12
    case d20 = 20
    case d100 = 100
}
extension NumberDie {
    public func roll<RNG: RandomNumberGenerator>(rng: inout RNG) -> Int {
        Int(rng.next(upperBound: UInt(rawValue - 1))) + 1
    }

    public func roll<RNG: RandomNumberGenerator>(
        withModifier advantageNumber: RollModifier?,
        rng: inout RNG
    ) -> Int {
        switch advantageNumber {
        case .disadvantage:
            let firstRoll = self.roll(rng: &rng)
            let secondRoll = self.roll(rng: &rng)
            return min(firstRoll, secondRoll)
        case .advantage:
            let firstRoll = self.roll(rng: &rng)
            let secondRoll = self.roll(rng: &rng)
            return max(firstRoll, secondRoll)
        default:
            let roll = self.roll(rng: &rng)
            return roll
        }
    }
}

extension NumberDie: CustomStringConvertible {
    public var description: String {
        "d\(rawValue)"
    }
}

public enum PlotDieResult: Sendable {
    case opportunity
    case complication2
    case complication4
    case none
}

public struct RandomDistribution: Sendable {
    public var dice: [(die: NumberDie, count: Int)]

    public var asArray: [NumberDie] {
        dice.flatMap { (die, count) in Array(repeating: die, count: count) }
    }
}

// Measured in ft
public typealias Distance = Int
// Measured in diamond marks or mk
public typealias Money = Int
// Measured in lb
public typealias Weight = Int

public struct Resource: Sendable, Comparable {
    public var value: Int
    public var maxValue: Int
    public mutating func restore(_ delta: Int) {
        value += max(min(delta, maxValue - value), 0)
    }

    public static func < (lhs: Resource, rhs: Resource) -> Bool {
        lhs.value < rhs.value
    }

    public init(value: Int? = nil, maxValue: Int) {
        self.value = value ?? maxValue
        self.maxValue = maxValue
    }
}
