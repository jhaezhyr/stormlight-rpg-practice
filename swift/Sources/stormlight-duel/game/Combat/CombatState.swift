public protocol RpgCharacterCombatStateSharedProtocol {
    var space: Space1D { get }
    var turnSpeed: TurnSpeed { get }
    var actionsRemaining: Int { get }
    var handsUsed: Set<Hand> { get }
    var actionsTaken: Set<CombatActionName> { get }
    var reactionsRemaining: Int { get }
    var recoveriesRemaining: Int { get }

    var turnsTaken: Int { get }
}

public struct RpgCharacterCombatState: RpgCharacterCombatStateSharedProtocol {
    public var space: Space1D
    public var turnSpeed: TurnSpeed = .fast
    public var actionsRemaining: Int = 0
    public var handsUsed: Set<Hand> = []
    public var actionsTaken: Set<CombatActionName> = []
    public var reactionsRemaining: Int = 1
    public var recoveriesRemaining: Int = 1

    public var turnsTaken: Int = 0

    public var reactionProviders: [any Responder]

    public init(
        space: Space1D,
        turnSpeed: TurnSpeed? = nil,
        actionsRemaining: Int? = nil,
        handsUsed: Set<Hand>? = nil,
        actionsTaken: Set<CombatActionName>? = nil,
        reactionsRemaining: Int? = nil,
        hasStrikeAdvantageOver: Set<RpgCharacterRef>? = nil,
        for characterRef: RpgCharacterRef,
        in gameSession: isolated GameSession = #isolation
    ) {
        self.space = space
        if let turnSpeed { self.turnSpeed = turnSpeed }
        if let actionsRemaining { self.actionsRemaining = actionsRemaining }
        if let handsUsed { self.handsUsed = handsUsed }
        if let actionsTaken { self.actionsTaken = actionsTaken }
        if let reactionsRemaining { self.reactionsRemaining = reactionsRemaining }
        self.reactionProviders = [
            DodgeProvider(for: characterRef),
            ReactiveStrikeProvider(for: characterRef),
        ]
    }

    func snapshot(in gameSession: isolated GameSession = #isolation)
        -> RpgCharacterCombatStateSnapshot
    {
        .init(
            space: space,
            turnSpeed: turnSpeed,
            actionsRemaining: actionsRemaining,
            handsUsed: handsUsed,
            actionsTaken: actionsTaken,
            reactionsRemaining: reactionsRemaining,
            recoveriesRemaining: recoveriesRemaining,
            turnsTaken: turnsTaken,
        )
    }
}

public struct RpgCharacterCombatStateSnapshot: RpgCharacterCombatStateSharedProtocol, Sendable {
    public var space: Space1D
    public var turnSpeed: TurnSpeed
    public var actionsRemaining: Int
    public var handsUsed: Set<Hand>
    public var actionsTaken: Set<CombatActionName>
    public var reactionsRemaining: Int
    public var recoveriesRemaining: Int

    public var turnsTaken: Int
}

public typealias Vector1D = Int
public typealias Position1D = Vector1D

public struct Space1D: Equatable, Hashable, Sendable {
    public var origin: Position1D
    public var size: Distance
    public var orientation: Direction1D

    public var lo: Position1D {
        orientation == .right ? origin : origin - size
    }
    public var hi: Position1D {
        orientation == .right ? origin + size : origin
    }

    public init(
        origin: Position1D,
        size: Distance,
        orientation: Direction1D = .right
    ) {
        self.origin = origin
        self.size = size
        self.orientation = orientation
    }

    public init(
        _ range: Range<Position1D>
    ) {
        self.init(origin: range.lowerBound, size: range.upperBound - range.lowerBound)
    }

    public func distance(to other: Position1D) -> Distance {
        let lo = lo
        let hi = hi
        if other < lo {
            return lo - other
        } else if other > hi {
            return other - hi
        } else {
            return 0
        }
    }

    public func distance(to other: Space1D) -> Distance {
        min(distance(to: other.lo), distance(to: other.hi))
    }

    public func overlaps(_ other: Self) -> Bool {
        let (lhLo, lhHi) = (lo, hi)
        let (rhLo, rhHi) = (other.lo, other.hi)
        let lh = lhLo..<lhHi
        let rh = rhLo..<rhHi
        return rh.contains(lhLo) || rh.contains(lhHi - 1)
            || lh.contains(rhLo) || lh.contains(rhHi - 1)
    }

    public func touchesOrOverlaps(_ other: Self) -> Bool {
        let (lhLo, lhHi) = (lo, hi)
        let (rhLo, rhHi) = (other.lo, other.hi)
        let lh = lhLo..<lhHi
        let rh = rhLo..<rhHi
        return rh.contains(lhLo) || rh.contains(lhHi)
            || lh.contains(rhLo) || lh.contains(rhHi)
    }

    public func facing(_ newOrientation: Direction1D) -> Self {
        if orientation == self.orientation {
            return self
        }
        switch orientation {
        case .left: return .init(origin: origin + size, size: size, orientation: .right)
        case .right: return .init(origin: origin - size, size: size, orientation: .left)
        }
    }

    public func expanded(by amount: Distance) -> Self {
        var result = self
        result.size += 2 * amount
        result.origin -= orientation == .right ? amount : -amount
        return result
    }

    public static func + (lh: Self, rh: Vector1D) -> Self {
        .init(origin: lh.origin + rh, size: lh.size, orientation: lh.orientation)
    }

    public static func - (lh: Self, rh: Vector1D) -> Self {
        .init(origin: lh.origin - rh, size: lh.size, orientation: lh.orientation)
    }
}

extension Space1D: CustomStringConvertible {
    public var description: String {
        "\(lo)\(orientation == .left ? "<=" : "->")\(hi)"
    }
}
