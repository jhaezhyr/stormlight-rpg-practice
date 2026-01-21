import Testing
import stormlight_duel

@Test("afflicted does damage every turn")
func afflicted() async throws {
    let session = GameSession(
        game: Game(
            characters: [PlayerRpgCharacter.basicCharacter()],
            broadcaster: SilentBroadcaster()
        )
    )
    func doIt(in session: isolated GameSession) async {
        let playerRef = session.game.characters.first!.primaryKey
        session.game.characters[playerRef]!.conditions.upsert(
            AnyCondition(
                DurationCondition(
                    core: Afflicted(damagePerTurn: Damage(2, type: .vital), in: session),
                    duration: 3,
                    in: session
                )
            )
        )

        // Simulate the end of this character's turn
        var playerHealth: Int { session.game.characters[playerRef]!.health.value }
        #expect(playerHealth == 12)
        await session.game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef, in: session)
        #expect(playerHealth == 10)
        await session.game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef, in: session)
        #expect(playerHealth == 8)
        await session.game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef, in: session)
        #expect(playerHealth == 6)
        await session.game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef, in: session)
        // After three turns, it should remove itself
        // TODO And it does, but there's some strange ordering shenanigans.
        // Figure out how to properly order listeners within the same HookTrigger
        // Additionally, make sure that either condition types know how to check whether they've already been removed so they don't run,
        //   or figure out how to make the dispatch function not run the condition's action when the condition has already been removed.
        #expect(playerHealth == 6)
        await session.game.naiveDispatch(CombatPhase.endOfTurn, for: playerRef, in: session)
        #expect(playerHealth == 6)
    }
    await doIt(in: session)
}
