//
//  Test.swift
//  Shared
//
//  Created by Brent Crowley on 17/9/2025.
//

@testable import GameEngine
import Foundation
import Models
import Testing

struct WaitingForDrawCommandTests {
    @Test(
        "Success - Player picks up cards from draw pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func successPickUpFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var gameEngine = try gameEngineWithNumPlayers(.four, playerUp: player)
        let action = Action<GameEngine>.pickUpFromDrawPile
        let command: Command<GameEngine> = action.command()

        // WHEN
        try command.execute(on: &gameEngine)

        // THEN
        #expect(gameEngine.game.deck.cards[0...1].map(\.location) == [.playerHand(player), .playerHand(player)])
        #expect(gameEngine.game.phase == .waitingForDiscard)
    }
   
    @Test(
        "Success - Player picks up last card from pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func successPickUpsUpOneCardFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var gameEngine = try gameEngineWithNumPlayers(.four, playerUp: player)
        // Make only last card draw pile card
        gameEngine.game.deck.cards
            .filter { $0.id != gameEngine.game.deck.cards.last?.id }
            .forEach { gameEngine.game.update(cardID: $0.id, toLocation: .pile(.discardRight)) }

        let action = Action<GameEngine>.pickUpFromDrawPile
        let command: Command<GameEngine> = action.command()

        // WHEN
        try command.execute(on: &gameEngine)

        // THEN
        #expect(gameEngine.game.deck.cards.last?.location == .playerHand(player))
        #expect(gameEngine.game.phase == .waitingForDiscard)
    }
   
    @Test(
        "Error - Player picks up cards from empty draw pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func errorPickUpFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var gameEngine = GameEngine(dataProvider: .testValue())
        // Remove all the cards from the draw pile.
        gameEngine.game.deck.cards.forEach { gameEngine.game.update(cardID: $0.id, toLocation: .pile(.discardLeft)) }

        let action = Action<GameEngine>.pickUpFromDrawPile
        let command: Command<GameEngine> = action.command()

        // WHEN
        #expect(
            throws: Deck.Error.pileEmpty(.draw),
            performing: { try command.execute(on: &gameEngine) }
        )
    }
   
    @Test("Success - Discard to left pile")
    func successDiscardCardToLeftPile() throws {
        // GIVEN
        var gameEngine = try GameEngine.makeTestSubject()
        let firstCard = try #require(gameEngine.game.deck.cards.first)
        let action = Action<GameEngine>.discardToLeftPile(cardID: firstCard.id)
        let command: Command<GameEngine> = action.command()

        // WHEN
        try command.execute(on: &gameEngine)

        // THEN
        #expect(gameEngine.game.deck.cards.first?.location == .pile(.discardLeft))
    }
   
    @Test("Success - Discard to right pile")
    func successDiscardCardToRightPile() throws {
        // GIVEN
        var gameEngine = try GameEngine.makeTestSubject()
        let firstCard = try #require(gameEngine.game.deck.cards.first)
        let action = Action<GameEngine>.discardToRightPile(cardID: firstCard.id)
        let command: Command<GameEngine> = action.command()

        // WHEN
        try command.execute(on: &gameEngine)

        // THEN
        #expect(gameEngine.game.deck.cards.first?.location == .pile(.discardRight))
    }
}

extension WaitingForDrawCommandTests {
    private func gameEngineWithNumPlayers(_ playersInGame: Player.InGameCount, playerUp: Player.Up) throws -> GameEngine {
        var dataProvider = GameEngine.DataProvider.testValue()
        dataProvider.newGameID = { .mockGameID() }
        dataProvider.deck = { .testMock }
        var gameEngine = GameEngine(dataProvider: dataProvider)
        try gameEngine.performAction(.system(.createGame(players: playersInGame)))
        switch playerUp {
        case .one: break
        case .two:
            gameEngine.game.nextPlayer()
        case .three:
            gameEngine.game.nextPlayer()
            gameEngine.game.nextPlayer() // Get to player 3
        case .four:
            gameEngine.game.nextPlayer()
            gameEngine.game.nextPlayer()
            gameEngine.game.nextPlayer() // Get to player 4
        }

        return gameEngine
    }
}

