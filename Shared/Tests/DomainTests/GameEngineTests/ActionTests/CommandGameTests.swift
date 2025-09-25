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

struct CommandGameTests {
    @Test(
        "Success - Player picks up cards from draw pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func successPickUpFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var game = gameWithNumPlayers(.four, playerUp: player)
        let action = Action<Game>.pickUpFromDrawPile
        let command: Command<Game> = action.command()

        // WHEN
        try command.execute(on: &game)
   
        // THEN
        #expect(game.deck.cards[0...1].map(\.location) == [.playerHand(player), .playerHand(player)])
        #expect(game.phase == .waitingForDiscard)
    }
   
    @Test(
        "Success - Player picks up last card from pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func successPickUpsUpOneCardFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var game = gameWithNumPlayers(.four, playerUp: player)
        // Make only last card draw pile card
        game.deck.cards
            .filter { $0.id != game.deck.cards.last?.id }
            .forEach { game.update(cardID: $0.id, toLocation: .pile(.discardRight)) }
   
        let action = Action<Game>.pickUpFromDrawPile
        let command: Command<Game> = action.command()

        // WHEN
        try command.execute(on: &game)
   
        // THEN
        #expect(game.deck.cards.last?.location == .playerHand(player))
        #expect(game.phase == .waitingForDiscard)
    }
   
    @Test(
        "Error - Player picks up cards from empty draw pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func errorPickUpFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var game = Game.testMock(id: .mockID)
        // Remove all the cards from the draw pile.
        game.deck.cards.forEach { game.update(cardID: $0.id, toLocation: .pile(.discardLeft)) }
   
        let action = Action<Game>.pickUpFromDrawPile
        let command: Command<Game> = action.command()

        // WHEN
        #expect(
            throws: Deck.Error.pileEmpty(.draw),
            performing: { try command.execute(on: &game) }
        )
    }
   
    @Test("Success - Discard to left pile")
    func successDiscardCardToLeftPile() throws {
        // GIVEN
        var game = Game.testMock(id: .mockID)
        let firstCard = try #require(game.deck.cards.first)
        let action = Action<Game>.discardToLeftPile(cardID: firstCard.id)
        let command: Command<Game> = action.command()

        // WHEN
        try command.execute(on: &game)

        // THEN
        #expect(game.deck.cards.first?.location == .pile(.discardLeft))
    }
   
    @Test("Success - Discard to right pile")
    func successDiscardCardToRightPile() throws {
        // GIVEN
        var game = Game.testMock(id: .mockID)
        let firstCard = try #require(game.deck.cards.first)
        let action = Action<Game>.discardToRightPile(cardID: firstCard.id)
        let command: Command<Game> = action.command()

        // WHEN
        try command.execute(on: &game)
   
        // THEN
        #expect(game.deck.cards.first?.location == .pile(.discardRight))
    }
}

extension CommandGameTests {
    private func gameWithNumPlayers(_ playersInGame: Player.InGameCount, playerUp: Player.Up) -> Game {
        var game = Game(id: .mockID, cards: .testMock, playersInGame: playersInGame)
        switch playerUp {
        case .one: break
        case .two:
            game.nextPlayer()
        case .three:
            game.nextPlayer()
            game.nextPlayer() // Get to player 3
        case .four:
            game.nextPlayer()
            game.nextPlayer()
            game.nextPlayer() // Get to player 4
        }

        return game
    }
}

extension UUID {
    fileprivate static let mockID: Self = .init(0)
}
