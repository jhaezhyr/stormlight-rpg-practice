import stormlight_duel
import text_brain

public struct CliInterfaceConnection: TextInterfaceConnection {
    let characterRef: RpgCharacterRef

    init(for characterRef: RpgCharacterRef) {
        self.characterRef = characterRef
    }

    public func getAnswer() throws -> String {
        print("  > ", terminator: "")
        if let result = readLine() {
            return result
        } else {
            throw CliInterfaceConnectionError.noMoreInput
        }
    }

    public func display(_ type: String, message: String, interface: String?) async {
        switch type {
        case "event":
            print("\(characterRef.name): \(message)")
            if let interface {
                print(interface)
            }
            try? await Task.sleep(for: .seconds(0.1))
        case "hint":
            print("\(message)")
            if let interface {
                print(interface)
            }
            try? await Task.sleep(for: .seconds(0.1))
        case "prompt":
            if let interface {
                print(interface)
            }
            print("\(characterRef.name): \(message)")
        default:
            fatalError("What do I do with this?")
        }
    }
}

enum CliInterfaceConnectionError: Error {
    case noMoreInput
}
