//
//  Test.swift
//  Shared
//
//  Created by Brent Crowley on 13/10/2025.
//

@testable import GameEngine
import Models
import Testing

struct RoundSimulationTests {
    @Test("Simulate Round")
    func simulateRound() throws {
        // GIVEN
        let (stream, continuation) = AsyncStream<GameEngine.Event>.makeStream()
        let sendEvent: @Sendable (_ event: GameEngine.Event) -> Void = { [continuation] in continuation.yield($0) }
        let dataProvider = GameEngine.DataProvider(
            deck: { .roundDeck },
            newGameID: { .mockGameID() },
            saveGame: { _ in },
            shuffleCards: { $0 },
            streamOfGameEngineEvents: { [stream] in stream },
            sendEvent: sendEvent
        )
        var testSubject = GameEngine(dataProvider: dataProvider)

        // WHEN
        try testSubject.performAction(.system(.createGame(players: .two)))

        // THEN - Set up game
        #expect(testSubject.game.id == .mockGameID())
        #expect(testSubject.game.deck.leftDiscardPile.first == .init(id: 0, kind: .duo(.crab), color: .lightBlue, location: .pile(.discardLeft)))
        #expect(testSubject.game.deck.rightDiscardPile.first == .init(id: 1, kind: .collector(.shell), color: .lightGrey, location: .pile(.discardRight)))
        #expect(testSubject.game.phase == .waitingForDraw)

        // Simulate turns
        try player1Turn1(&testSubject)
        try player2Turn1(&testSubject)

        try player1Turn2(&testSubject)
    }
}

extension RoundSimulationTests {
    private func player1Turn1(_ testSubject: inout GameEngine) throws {
        // WHEN - 1up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        #expect(
            [
                Card.init(id: 2, kind: .collector(.octopus), color: .lightGreen, location: .playerHand(.one)),
                Card.init(id: 3, kind: .duo(.shark), color: .black, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - 1up discards black shark to right pile
        // Action: Black shark to discard right
        try testSubject.performAction(.user(.discardToRightPile(3))) // ID of shark

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 3) // ID of Shark
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn1(_ testSubject: inout GameEngine) throws {
        // WHEN - 2up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        #expect(
            [
                Card.init(id: 4, kind: .duo(.crab), color: .lightBlue, location: .playerHand(.two)),
                Card.init(id: 5, kind: .duo(.fish), color: .black, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - 2up discards black fish to right pile
        try testSubject.performAction(.user(.discardToLeftPile(5))) // ID of fish
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 5) // ID of Fish
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn2(_ testSubject: inout GameEngine) throws {
        // WHEN - 1up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        // Mermaid
        // Ship yellow
        #expect(
            [
                Card.init(id: 6, kind: .mermaid, color: .white, location: .playerHand(.one)),
                Card.init(id: 7, kind: .duo(.ship), color: .yellow, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // Discard ship to right
        // WHEN - 1up discards ship to right pile
        try testSubject.performAction(.user(.discardToRightPile(7))) // ID of ship

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 7) // ID of Shark
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }
}

extension Array where Element == Card {
    fileprivate static let roundDeck: Self = [
        .duo(.crab, id: 0, color: .lightBlue), // Crab light Blue -> Discard left
        .collector(.shell, id: 1, color: .lightGrey), // Shell Grey -> Discard right
        .collector(.octopus, id: 2, color: .lightGreen), // Octopus light Green (1up draw)
        .duo(.shark, id: 3, color: .black), // Black shark (1up draw)
        .duo(.crab, id: 4, color: .lightBlue), // Crab light blue (2up draw)
        .duo(.fish, id: 5, color: .black), // Black fish (2up draw)

        .mermaid(id: 6), // Mermaid (1up draw)
        .duo(.ship, id: 7, color: .yellow), // Ship yellow (1up draw)
    ]
}

// 2up
// 
// Draw two cards
// 
// Fish dark blue
// Ship light blue
// Discard fish dark blue to right discard
// 
// end turn
// 
// 
// 
// 1up
// 
// Draw two cards
// 
// Shark light green
// Multiplier penguin light green.
// Discard shark light green to left.
// 
// 
// 
// 2up
// 
// Draw two cards
// 
// Crab black
// Ship dark blue
// Discard crab black to left discard
// 
// Play pair of ships (Should trigger next turn)
// 
// Pick up crab black from left discard
// 
// End turn
// 
// 
// 
// 1up
// 
// Draw two cards
// 
// Shark light blue
// Penguin pink
// Discard shark light blue to left
// 
// end turn
// 
// 
// 
// 2up
// 
// Draw two cards
// 
// Fish light green
// Fish dark blue
// Discard light green fish to left
// 
// Play pair of crabs
// 
// Pick up light green fish
// 
// Play pair of fish
// 
// Draw one card
// 
// Ship black
// End turn
// 
// 
// 
// 1up
// 
// Draw two cards
// 
// Fish yellow
// Sailor pink
// Discard sailor pink to right.
// 
// end turn
// 
// 
// 
// 2up
// 
// Draw two cards
// 
// Swimmer yellow
// Ship black
// Discard swimmer yellow to discard left.
// 
// Play pair of ships
// 
// Draw two cards
// 
// Shark dark blue
// Swimmer dark blue
// Discard dark blue swimmer to right
// 
// End turn
// 
// 
// 
// 1up
// 
// Draw two cards
// 
// Fish black
// Mermaid
// Discard black fish to right
// 
// end turn
// 
// 
// 
// 2up
// 
// Pick up swimmer yellow from left discard
// 
// Play steal card -> Stole yellow fish from 1up.
// 
// End turn
// 
// 
// 
// 1up
// 
// Draw two cards
// 
// Shark purple
// Ship yellow
// Discard shark to left discard
// 
// end turn
// 
// 
// 
// 2up
// 
// Pick up black fish from right discard
// 
// Play pair of fish
// 
// PIck upp one card from draw pile
// 
// Shell black
// End turn
// 
// 
// 
// 1up
// 
// Draw two cards
// 
// Shell dark blue
// Crab dark blue
// Discard crab dark bllue to left discard
// 
// End turn
// 
// 
// 
// 2up
// 
// Draw two cards
// 
// Penguin purple
// Shell yellow
// Discard purple penguin to right
// 
// End round with STOP
// 
// 
// 
// Count scores
// 
// 2up
// 
// Duos: 6
// 
// Multipliers: 0
// 
// Mermaid: 0
// 
// Collector: 2
// 
// Total 8
// 
// 
// 
// 1up
// 
// Duos: 0
// 
// Multipliers: 2 (Penguin)
// 
// Mermaid: 2 (light green), 1 for other color
// 
// Collector: 1 (penguin)
// 
// Total 6
