import Testing
import stormlight_duel

@Test("afflicted does damage every turn")
func afflicted() async throws {
    let playerToPlayWith = PlayerRpgCharacter.basicCharacter()
    playerToPlayWith.conditions.append(
        DurationCondition(type: Afflicted(damagePerTurn: Damage(2, realm: .vital)), duration: 3)
    )
    let playerRef = RpgCharacterRef(name: playerToPlayWith.name)
    var game = Game(characters: [playerToPlayWith])
    let player = game.character(at: playerRef, as: PlayerRpgCharacter.self)!
    // Simulate the end of this character's turn
    var playerHealth: Int { player.health.value }
    #expect(playerHealth == 12)
    game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef)
    #expect(playerHealth == 10)
    game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef)
    #expect(playerHealth == 8)
    game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef)
    #expect(playerHealth == 6)
    game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef)
    // After three turns, it should remove itself
    // TODO And it does, but there's some strange ordering shenanigans.
    // Figure out how to properly order listeners within the same HookTrigger
    // Additionally, make sure that either condition types know how to check whether they've already been removed so they don't run,
    //   or figure out how to make the dispatch function not run the condition's action when the condition has already been removed.
    #expect(playerHealth == 6)
    game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef)
    #expect(playerHealth == 6)
}
