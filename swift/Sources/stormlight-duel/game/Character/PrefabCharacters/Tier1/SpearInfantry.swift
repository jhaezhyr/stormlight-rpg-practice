import CompleteDictionary
import KeyedSet

// Human level 0 spearman
extension PrefabCharacters {
    static func spearInfantry(
        ref: RpgCharacterRef? = nil,
        homeCulture: CultureName = .alethi,
        isPlayer: Bool,
        brain: RpgCharacterBrain,
        in gameSession: isolated GameSession = #isolation
    ) -> PlayerRpgCharacter {
        let ref = ref ?? RpgCharacterRef(name: "Spear Infantry")
        return PlayerRpgCharacter(
            name: ref.name,
            expertises: [
                .weapon(.shortspear),
                .weapon(.javelin),
                .culture(homeCulture),
            ],
            equipment: [
                .init(BasicArmorTypes.chain(), isReady: true),
                .init(basicWeapons[.shortspear]!(gameSession), isReady: true),
                .init(basicWeapons[.shortbow]!(gameSession), isReady: true),
            ],
            attributes: [
                .strength: 2,
                .speed: 2,
                .intellect: 1,
                .willpower: 1,
                .awareness: 2,
                .presence: 1,
            ],
            ranksInCoreSkills: CompleteDictionary<CoreSkillName, Int> {
                skill in
                switch skill {
                case .athletics: 2
                case .heavyWeaponry: 2
                case .lightWeaponry: 2
                case .discipline: 1
                case .intimidation: 2
                case .perception: 3
                default: 0
                }
            },
            ranksInOtherSkills: [:],
            health: Resource(maxValue: Int.random(in: 11...17, using: &gameSession.game.rng)),
            focus: Resource(maxValue: 3),
            investiture: Resource(maxValue: 0),
            reach: 0,
            features: [
                .init(MinionFeature()),
                .init(MartialDrillFeature()),
                .init(MilitaryTacticsFeature()),
                .init(ShieldBashActionFeature()),
            ],
            conditions: [],
            brain: brain,
            isPlayer: isPlayer,
        )
    }
}

public struct MartialDrillFeature: CharacterFeature, CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { "Martial Drill" }
    // TODO Fill out this stub
}

public struct MilitaryTacticsFeature: CharacterFeature, CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { "Military Tactics" }
    // TODO Fill out this stub
}

public struct ShieldBashActionFeature: CharacterFeature, CharacterFeatureSnapshot {
    public var name: CharacterFeatureRef { "Shield Bash action" }
    // TODO Fill out this stub
}
