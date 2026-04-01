import Foundation

actor Lobby {
    static let shared = Lobby()
    private var pendingMatches: [String: CheckedContinuation<WebTextInterfaceConnection, Error>] =
        [:]

    // Host suspends here until a guest joins. Returns the guest's connection.
    func hostMatch(arenaCode: String) async throws -> WebTextInterfaceConnection {
        try await withCheckedThrowingContinuation { pendingMatches[arenaCode] = $0 }
    }

    // Guest calls this, resumes host's continuation. Throws if code invalid.
    func joinMatch(arenaCode: String, guestConnection: WebTextInterfaceConnection) throws {
        guard let cont = pendingMatches.removeValue(forKey: arenaCode) else {
            throw LobbyError.noSuchArenaCode
        }
        cont.resume(returning: guestConnection)
    }

    func cancelMatch(arenaCode: String) {
        pendingMatches.removeValue(forKey: arenaCode)?.resume(throwing: LobbyError.hostCancelled)
    }
}

enum LobbyError: Error {
    case noSuchArenaCode
    case hostCancelled
}

func generateArenaCode() -> String {
    String((0..<6).map { _ in "ABCDEFGHJKLMNPQRSTUVWXYZ".randomElement()! })
}
