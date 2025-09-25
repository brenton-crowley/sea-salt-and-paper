@testable import GameEngine
import Dependencies
import Foundation
import Models
import OrderedCollections
import Testing

struct GameEngineTests {
    @Test(
        "Success - Create new game",
        arguments: [Player.InGameCount.two, .three, .four]
    )
    func successNewGame(players: Player.InGameCount) async throws {
        try await confirmation { confirmation in
            // GIVEN
            let mockCards = Array<Card>.gameEngineMockCards
            var dataProvider = GameEngine.DataProvider.testValue
            dataProvider.deck = { mockCards }
            dataProvider.saveGame = { _ in confirmation() }
            dataProvider.shuffleCards = { $0 }
            var testSubject = GameEngine(dataProvider: dataProvider)

            // WHEN
            try testSubject.performAction(.system(.createGame(players: players)))

            // THEN
            #expect(testSubject.game.id == .mockGameID())
            #expect(testSubject.game.deck.cards == OrderedSet(mockCards))
            #expect(testSubject.game.players.count == .number(of: players))
            #expect(testSubject.game.phase == .waitingForStart)
            #expect(testSubject.game.currentPlayerUp == .one)
            #expect(testSubject.game.deck.cards.count == mockCards.count)
        }
    }

    @Test("One Round - Two Players")
    func oneRound() async throws {
        try await confirmation { confirmation in
            // GIVEN
            var dataProvider = GameEngine.DataProvider.testValue
            dataProvider.saveGame = { _ in confirmation() }
            dataProvider.shuffleCards = { $0 }
            dataProvider.deck = {
                [
                    .duo(.crab, id: 0),
                    .duo(.crab, id: 1),
                    .duo(.ship, id: 2),
                    .duo(.ship, id: 3),
                    .duo(.fish, id: 4),
                    .duo(.fish, id: 5),
                    .duo(.swimmer, id: 6),
                    .duo(.ship, id: 7),

                ]
            }
            var testSubject = GameEngine(dataProvider: dataProvider)
            try testSubject.performAction(.system(.createGame(players: .two)))

            // WHEN


            // THEN
        }
    }
}

extension Int {
    fileprivate static func number(of players: Player.InGameCount) -> Self {
        switch players {
        case .two: 2
        case .three: 3
        case .four: 4
        }
    }
}

extension GameEngine.DataProvider {
    static var testValue: Self {
        .init(
            deck: { .gameEngineMockCards },
            newGameID: { .mockGameID() },
            saveGame: { _ in fatalError("Unimplemented") },
            shuffleCards: { _ in fatalError("Unimplemented") }
        )
    }

    static var testValueDefaults: Self {
        .init(
            deck: { .gameEngineMockCards },
            newGameID: { .mockGameID() },
            saveGame: { _ in },
            shuffleCards: { $0 }
        )
    }
}

extension UUID {
    fileprivate static func mockGameID(_ id: Int = 0) -> Self { UUID.init(id) }
}
