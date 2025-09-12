@testable import GameState
import Models
import Testing

struct GameStateTests {
    @Test("GameState init")
    func gameStateInit() {
        // GIVEN
        let dataProvider = GameState.DataProvider.make(
            deckRepository: .live,
            playersInGameCount: .two
        )

        // WHEN
        let testSubject = GameState(dataProvider: dataProvider)

        // THEN
        #expect(testSubject.phase == .waitingForDraw)
    }

    @Test(
        "Cycle through players",
        arguments: [Player.InGameCount.two, .three, .four]
    )
    func nextPlayerChangesCurrentPlayer(playersInGame: Player.InGameCount) async throws {
        // GIVEN
        let dataProvider = GameState.DataProvider.make(
            deckRepository: .mock,
            playersInGameCount: playersInGame
        )

        var testSubject = GameState(dataProvider: dataProvider)

        // Current player should be 1UP
        #expect(testSubject.currentPlayerUp == .one)

        // Cycle three the players depending on the players in the game
        switch playersInGame {
        case .two:
            testSubject.nextPlayer()
            #expect(testSubject.currentPlayerUp == .two, "Players in game: \(playersInGame)")

        case .three:
            testSubject.nextPlayer()
            #expect(testSubject.currentPlayerUp == .two)
            testSubject.nextPlayer()
            #expect(testSubject.currentPlayerUp == .three)
        case .four:
            testSubject.nextPlayer()
            #expect(testSubject.currentPlayerUp == .two)
            testSubject.nextPlayer()
            #expect(testSubject.currentPlayerUp == .three)
            testSubject.nextPlayer()
            #expect(testSubject.currentPlayerUp == .four)
        }

        // Next player should always be player one when at the end of the players in the game.
        testSubject.nextPlayer()
        #expect(testSubject.currentPlayerUp == .one)
    }

    @Test(
        "Setup Players",
        arguments: [Player.InGameCount.two, .three, .four]
    )
    func setupPlayers(playersInGame: Player.InGameCount) async throws {
        // GIVEN
        let dataProvider = GameState.DataProvider.make(
            deckRepository: .mock,
            playersInGameCount: playersInGame
        )

        // WHEN
        let testSubject = GameState(dataProvider: dataProvider)

        #expect(testSubject.currentPlayer == .init(id: .one))

        // THEN
        switch playersInGame {
        case .two: #expect(testSubject.players == .twoPlayers)
        case .three: #expect(testSubject.players == .threePlayers)
        case .four: #expect(testSubject.players == .fourPlayers)
        }
    }

    @Test("Deck setup")
    func deckSetup() {
        // GIVEN
        let dataProvider = GameState.DataProvider.make(
            deckRepository: .live, // Use the actual deck of cards
            playersInGameCount: .two
        )

        // WHEN
        let testSubject = GameState(dataProvider: dataProvider)

        // THEN
        #expect(testSubject.deck.cards.count == 58)
        #expect(testSubject.deck.cards.allSatisfy({ $0.location == .pile(.draw) }))
        #expect(testSubject.deck.drawPile.count == 58)
        #expect(testSubject.deck.leftDiscardPile.count == 0)
        #expect(testSubject.deck.rightDiscardPile.count == 0)
        #expect(testSubject.deck.cardsInHand(for: .one).count == 0)
        #expect(testSubject.deck.cardsInHand(for: .two).count == 0)
    }
}

extension Dictionary where Key == Player.ID, Value == Player {
    fileprivate static let twoPlayers: Self = [
        .one: .init(id: .one),
        .two: .init(id: .two)
    ]

    fileprivate static let threePlayers: Self = [
        .one: .init(id: .one),
        .two: .init(id: .two),
        .three: .init(id: .three)
    ]

    fileprivate static let fourPlayers: Self = [
        .one: .init(id: .one),
        .two: .init(id: .two),
        .three: .init(id: .three),
        .four: .init(id: .four),
    ]
}
