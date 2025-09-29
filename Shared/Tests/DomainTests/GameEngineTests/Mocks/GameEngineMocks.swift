@testable import GameEngine
import Foundation
import Models

extension GameEngine.DataProvider {
    static var testValue: Self {
        .init(
            deck: { .gameEngineMockCards },
            newGameID: { .mockGameID() },
            saveGame: { _ in fatalError("Unimplemented") },
            shuffleCards: { _ in fatalError("Unimplemented") },
            streamOfGameEngineEvents: { fatalError("Unimplemented") },
            sendEvent: { _ in fatalError("Unimplemented") }
        )
    }

    static func testValue(
        cards: [Card] = .gameEngineMockCards,
        newGameID: UUID = .mockGameID()
    ) -> Self {
        .init(
            deck: { cards },
            newGameID: { newGameID },
            saveGame: { _ in },
            shuffleCards: { $0 },
            streamOfGameEngineEvents: { .init { $0.finish() } },
            sendEvent: { _ in }
        )
    }
}

extension GameEngine {
    static func makeTestSubject(players: Player.InGameCount = .two) throws -> Self {
        var gameEngine = GameEngine(dataProvider: .testValue())
        try gameEngine.performAction(.system(.createGame(players: players)))
        return gameEngine
    }
}
