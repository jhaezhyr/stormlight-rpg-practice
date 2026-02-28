import Foundation
import HummingbirdWebSocket
import stormlight_duel
import text_brain

actor WebTextInterfaceConnection: TextInterfaceConnection {
    let outbound: WebSocketOutboundWriter
    var savedAnswers: [String] = []
    var shouldSkip: Bool = false

    init(outbound: WebSocketOutboundWriter) {
        self.outbound = outbound
    }

    func getAnswer() async throws -> String {
        while savedAnswers.isEmpty {
            try? await Task.sleep(for: .seconds(0.1))
            if Task.isCancelled || Task.isShuttingDownGracefully {
                throw CancellationError()
            }
        }
        return savedAnswers.removeFirst()
    }

    func storeAnswer(from newAnswer: WebSocketInboundMessageStream.Element) {
        switch newAnswer {
        case .text(let json):
            guard let jsonData = json.data(using: .utf8),
                let answer = try? JSONDecoder().decode(IncomingMessage.self, from: jsonData)
            else {
                print("Couldn't decode json \(json)")
                return
            }
            switch answer.type {
            case "skip":
                shouldSkip = true
            case "answer":
                savedAnswers.append(answer.message)
            default:
                print("What is this? \(answer)")
            }
        case .binary(let b):
            print("What is this thing? \(b)")
        }
    }

    func display(_ type: String, message: String, interface: String?) async {
        await send(OutboundMessage(type: type, message: message, interface: interface))
        do {
            switch type {
            case "hint":
                try await waitForSkip(for: .seconds(2.5 * min(Double(message.count) / 50, 1)))
            case "event":
                try await waitForSkip(for: .seconds(2.5 * min(Double(message.count) / 50, 1)))
            case "prompt":
                break
            default:
                fatalError("WHAT IS A \(type) EVENT?")
            }
        } catch {
            print("Error: \(error)")
            // Don't kill the program due to that.
        }
    }

    func waitForSkip(for duration: Duration) async throws {
        var timeWaited = Duration.seconds(0)
        let interval = Duration.milliseconds(250)
        while timeWaited < duration {
            if self.shouldSkip {
                shouldSkip = false
                break
            }
            try? await Task.sleep(for: interval)
            timeWaited += interval
            if Task.isCancelled || Task.isShuttingDownGracefully {
                throw CancellationError()
            }
        }
    }

    private func send(_ message: OutboundMessage) async {
        guard let data = try? JSONEncoder().encode(message),
            let json = String(data: data, encoding: .utf8)
        else {
            print("Couldn't encode message \(message)")
            return
        }
        do {
            try await outbound.write(.text(json))
        } catch {
            print("Couldn't send message \(json)")
        }
    }
}

struct OutboundMessage: Codable {
    var type: String
    var message: String
    var interface: String?
}

struct IncomingMessage: Codable {
    var type: String
    var message: String
}
