public func SurpriseComplication() -> some OpComp {
    return GiveConditionOpComp(name: "Surprise Attack") {
        (
            SingleTargetMessage(
                w1: "$1 is surprised!",
                wU: "You are surprised!",
                as1: $0
            ),
            Surprised(for: $0, in: $1)
        )
    }
}
