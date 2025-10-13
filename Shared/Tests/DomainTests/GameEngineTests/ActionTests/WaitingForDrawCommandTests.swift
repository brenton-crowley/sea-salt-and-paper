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
        var game = try gameWithNumPlayers(.four, playerUp: player)
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
        var game = try gameWithNumPlayers(.four, playerUp: player)
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
        var game = try gameWithNumPlayers(.four, playerUp: player)
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
        var game = Game.mock(id: .mockGameID())
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
        var game = Game.mock(id: .mockGameID())
        let firstCard = try #require(game.deck.cards.first)
        let action = Action<Game>.discardToRightPile(cardID: firstCard.id)
        let command: Command<Game> = action.command()

        // WHEN
        try command.execute(on: &game)

        // THEN
        #expect(game.deck.cards.first?.location == .pile(.discardRight))
    }

    @Test("Success - Pick up from right discard pile.", arguments: [Game.Phase.waitingForDraw, .resolvingEffect(.pickUpDiscard)])
    func successPickUpCardFromRightDiscardPile(gamePhase: Game.Phase) throws {
        // GIVEN
        let mockCards: [Card] = [
            .duo(.crab, id: 0, location: .pile(.discardRight)),
            .duo(.ship, id: 4, location: .pile(.discardRight)),
            .duo(.crab, id: 1, location: .pile(.discardLeft)),
            .duo(.crab, id: 2, location: .pile(.draw)),
        ]
        var game = Game(id: .mockGameID(), cards: mockCards, playersInGame: .two)
        game.set(phase: gamePhase)
        let action = Action<Game>.pickUpFromRightDiscardPile

        // Can play action
        #expect(action.rule().validate(on: game) == true)

        // WHEN
        try action.command().execute(on: &game)

        // THEN
        #expect(game.deck.cards.map(\.location) == [
            .pile(.discardRight),
            .playerHand(game.currentPlayerUp),
            .pile(.discardLeft),
            .pile(.draw),
        ])
    }

    @Test("Success - Pick up from left discard pile.", arguments: [Game.Phase.waitingForDraw, .resolvingEffect(.pickUpDiscard)])
    func successPickUpCardFromLeftDiscardPile(gamePhase: Game.Phase) throws {
        // GIVEN
        let mockCards: [Card] = [
            .duo(.crab, id: 0, location: .pile(.discardLeft)),
            .duo(.ship, id: 4, location: .pile(.discardLeft)),
            .duo(.crab, id: 1, location: .pile(.discardRight)),
            .duo(.crab, id: 2, location: .pile(.draw)),
        ]
        var game = Game(id: .mockGameID(), cards: mockCards, playersInGame: .two)
        game.set(phase: gamePhase)
        let action = Action<Game>.pickUpFromLeftDiscardPile

        // Can play action
        #expect(action.rule().validate(on: game) == true)

        // WHEN
        try action.command().execute(on: &game)

        // THEN
        #expect(game.deck.cards.map(\.location) == [
            .pile(.discardLeft),
            .playerHand(game.currentPlayerUp),
            .pile(.discardRight),
            .pile(.draw),
        ])
    }
}

extension WaitingForDrawCommandTests {
    private func gameWithNumPlayers(_ playersInGame: Player.InGameCount, playerUp: Player.Up) throws -> Game {
        var game = Game(id: .mockGameID(), cards: .gameEngineMockCards, playersInGame: playersInGame)
        switch playerUp {
        case .one: break
        case .two:
            game.setNextPlayerUp()
        case .three:
            game.setNextPlayerUp()
            game.setNextPlayerUp() // Get to player 3
        case .four:
            game.setNextPlayerUp()
            game.setNextPlayerUp()
            game.setNextPlayerUp() // Get to player 4
        }

        return game
    }
}

