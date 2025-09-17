//
//  Test.swift
//  Shared
//
//  Created by Brent Crowley on 17/9/2025.
//

@testable import Models
import Testing

struct CommandGameTests {
    @Test(
        "Success - Player picks up cards from draw pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func successPickUpFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var game = Game.testMock()
        let command: ThrowingCommand<Game> = .pickUpFromDrawPile(player: player)

        // WHEN
        try command.execute(on: &game)

        // THEN
        #expect(game.deck.cards[0...1].map(\.location) == [.player(player), .player(player)])
        #expect(game.phase == .waitingForDiscard)
    }

    @Test(
        "Success - Player picks up last card from pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func successPickUpsUpOneCardFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var game = Game.testMock()
        // Make only last card draw pile card
        game.deck.cards
            .filter { $0.id != game.deck.cards.last?.id }
            .forEach { game.deck.update(cardID: $0.id, toLocation: .pile(.discardRight)) }

        let command: ThrowingCommand<Game> = .pickUpFromDrawPile(player: player)

        // WHEN
        try command.execute(on: &game)

        // THEN
        #expect(game.deck.cards.last?.location == .player(player))
        #expect(game.phase == .waitingForDiscard)
    }

    @Test(
        "Error - Player picks up cards from empty draw pile",
        arguments: [Player.Up.one, .two, .three, .four]
    )
    func errorPickUpFromDrawPileExecute(player: Player.Up) throws {
        // GIVEN
        var game = Game.testMock()
        // Remove all the cards from the draw pile.
        game.deck.cards.forEach { game.deck.update(cardID: $0.id, toLocation: .pile(.discardLeft)) }

        let command: ThrowingCommand<Game> = .pickUpFromDrawPile(player: player)

        // WHEN
        #expect(
            throws: Deck.Error.pileEmpty(.draw),
            performing: { try command.execute(on: &game) }
        )
    }

    @Test(
        "Success - Change phase command",
        arguments: [Game.Phase.endRound, .endTurn, .resolvingEffects]
    )
    func successChangeGamePhaseTo(phase: Game.Phase) {
        // GIVEN
        let command: Command<Game> = .changePhase(to: phase)
        var game = Game.testMock()

        // WHEN
        command.execute(on: &game)

        // THEN
        #expect(game.phase == phase)
    }

    @Test("Success - Discard to left pile")
    func successDiscardCardToLeftPile() throws {
        // GIVEN
        var game = Game.testMock()
        let firstCard = try #require(game.deck.cards.first)
        let command: Command<Game> = .discardToLeftPile(cardID: firstCard.id)

        // WHEN
        command.execute(on: &game)

        // THEN
        #expect(game.deck.cards.first?.location == .pile(.discardLeft))
    }

    @Test("Success - Discard to right pile")
    func successDiscardCardToRightPile() throws {
        // GIVEN
        var game = Game.testMock()
        let firstCard = try #require(game.deck.cards.first)
        let command: Command<Game> = .discardToRightPile(cardID: firstCard.id)

        // WHEN
        command.execute(on: &game)

        // THEN
        #expect(game.deck.cards.first?.location == .pile(.discardRight))
    }
}

