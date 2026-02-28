public func UnbreakableOpportunity() -> some OpComp {
    GiveConditionOpComp(name: "Unbreakable") {
        (
            SingleTargetMessage(
                w1: "$1 becomes unbreakable, their defenses strengthen!",
                wU: "You become unbreakable, your defenses strengthen!",
                as1: $0
            ),
            DurationCondition(
                core: UnbreakableCondition(for: $0),
                duration: 2,
                turnsFor: $0,
                in: $1
            )
        )
    }
}
