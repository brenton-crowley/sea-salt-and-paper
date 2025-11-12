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
        try simulateRoundEndingWithPlayer2(&testSubject)

        // WHEN -
        try testSubject.performAction(.user(.endTurn))


        let scoreCalc = ScoreCalculator()
        let player1Cards = testSubject.game.deck.allCards(for: .one)
        let player2Cards = testSubject.game.deck.allCards(for: .two)

        let playerOneScore = scoreCalc.score(playerRound: player1Cards)
        let playerTwoScore = scoreCalc.score(playerRound: player2Cards)

        #expect(playerOneScore == 6)
        #expect(playerTwoScore == 8)
    }
    
    @Test("Success - Simulate round with player 2 calling 'stop' to end round")
    func successSimulateRoundWithPlayer2CallingStopToEndRound() async throws {
        // CONTEXT: If a player says STOP, all players score the points on their cards
        // - The round of scores should be capture on the game. Probably in a property [Round] where we can identify a player's score with a player.
        // - Once the round is over, we should start a new round.
        // - The next player is the player after the one who called STOP.
        // Use Deck.roundDeck for deterministic tests
        
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
        try simulateRoundEndingWithPlayer2(&testSubject)

        // WHEN - Player calls stop
        try testSubject.performAction(.user(.endRound(.stop)))
        
        // THEN
        #expect(testSubject.game.phase == .roundEnded(.stop))
        #expect(testSubject.game.currentRound?.state == .endReason(.stop, caller: Player.ID.two))
        
        // WHEN - Player completes round (Proceed)
        try testSubject.performAction(.user(.completeRound))
        
        // THEN
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
        #expect(testSubject.game.currentRound?.state == .inProgress)
        #expect(testSubject.game.rounds.first?.state == .complete)

        // Validate scores
        #expect(testSubject.game.rounds[0].points[.one] == 6)
        #expect(testSubject.game.rounds[0].points[.two] == 8)

        #expect(testSubject.game.scores[.one] == 6)
        #expect(testSubject.game.scores[.two] == 8)
        #expect(testSubject.game.scores[.three] == nil)
        #expect(testSubject.game.scores[.four] == nil)
        
        // No winner
        #expect(testSubject.game.winner == nil)
        #expect(testSubject.game.phase != .endGame)
    }
    
    @Test("Success - 2UP won last chance call round simulation")
    func success2UPWonLastChanceCallRoundSimulation() async throws {
        // TODO: AI Implement this test
        // CONTEXT: If a player says LAST CHANCE, then all other players each take a final turn, reveal their cards and count their points.
        // - If BET WON by player: their score is higher or equal to that of their opponents.
        // - They score the points of their cards PLUS the color bonus.
        // Their opponents only score their color bonus.
        // - If BET LOST: the player's score is less than that of any opponent.
        // The player who called stop only score their color bonus.
        // Their opponents score the points of their cards.
        // Use Deck.roundDeck for deterministic tests
        
        // GIVEN
        let (stream, continuation) = AsyncStream<GameEngine.Event>.makeStream()
        let sendEvent: @Sendable (_ event: GameEngine.Event) -> Void = { [continuation] in continuation.yield($0) }
        let dataProvider = GameEngine.DataProvider(
            deck: { .roundDeck + .lastChanceBetWon }, // Set up deck so that 2UP will win
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
        try simulateRoundEndingWithPlayer2(&testSubject)
        
        // WHEN - Player calls stop
        try testSubject.performAction(.user(.endRound(.lastChance)))
        
        // THEN
        #expect(testSubject.game.currentRound?.state == .endReason(.lastChance, caller: .two))
        #expect(testSubject.game.currentPlayerUp == .one)
        #expect(testSubject.game.phase == .waitingForDraw)
        
        // WHEN - Player one has final turn
        try player1Turn9_lastChanceWon(&testSubject)
        
        // THEN
        #expect(testSubject.actionIsPlayable(.user(.endTurn)) == false)
        #expect(testSubject.actionIsPlayable(.user(.completeRound)) == true)
        #expect(testSubject.game.phase == .roundEnded(.lastChance))
        
        // WHEN - Player completes round
        try testSubject.performAction(.user(.completeRound))
        
        // THEN
        // Player 2 score is 8 + color bonus
        #expect(testSubject.game.rounds[0].points[.one] == 2) // Only color bonus
        #expect(testSubject.game.rounds[0].points[.two] == 13) // 8 + 5
        #expect(testSubject.game.scores[.one] == 2) // Only color bonus
        #expect(testSubject.game.scores[.two] == 13) // 8 + 5
        // Player 1 score only score color bonus
    }
    
    @Test("Success - 2UP lost last chance call round simulation")
    func success2UPLostLastChanceCallRoundSimulation() async throws {
        // GIVEN
        let (stream, continuation) = AsyncStream<GameEngine.Event>.makeStream()
        let sendEvent: @Sendable (_ event: GameEngine.Event) -> Void = { [continuation] in continuation.yield($0) }
        let dataProvider = GameEngine.DataProvider(
            deck: { .roundDeck + .lastChanceBetLost }, // Set up the deck so that 2UP will lose.
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
        try simulateRoundEndingWithPlayer2(&testSubject)
        
        // WHEN - Player calls stop
        try testSubject.performAction(.user(.endRound(.lastChance)))
        
        // THEN
        #expect(testSubject.game.currentRound?.state == .endReason(.lastChance, caller: .two))
        #expect(testSubject.game.currentPlayerUp == .one)
        #expect(testSubject.game.phase == .waitingForDraw)
        
        // WHEN - Player one has final turn
        try player1Turn9_lastChanceLost(&testSubject)
        
        // THEN
        #expect(testSubject.actionIsPlayable(.user(.endTurn)) == false)
        #expect(testSubject.actionIsPlayable(.user(.completeRound)) == true)
        #expect(testSubject.game.phase == .roundEnded(.lastChance))
        
        // WHEN - Player completes round
        try testSubject.performAction(.user(.completeRound))
        
        // THEN
        #expect(testSubject.game.rounds[0].points[.one] == 10) // Points in hand
        #expect(testSubject.game.rounds[0].points[.two] == 5) // Color bonus only
        #expect(testSubject.game.scores[.one] == 10) // Points in hand
        #expect(testSubject.game.scores[.two] == 5) // Color bonus only
    }
    
    // TODO: Implement test for the game over conditions when a player scores more than 40
}

extension RoundSimulationTests {
    private func simulateRoundEndingWithPlayer2(_ testSubject: inout GameEngine) throws {
        try player1Turn1(&testSubject)
        try player2Turn1(&testSubject)

        try player1Turn2(&testSubject)
        try player2Turn2(&testSubject)

        try player1Turn3(&testSubject)
        try player2Turn3(&testSubject)

        try player1Turn4(&testSubject)
        try player2Turn4(&testSubject)

        try player1Turn5(&testSubject)
        try player2Turn5(&testSubject)

        try player1Turn6(&testSubject)
        try player2Turn6(&testSubject)

        try player1Turn7(&testSubject)
        try player2Turn7(&testSubject)

        try player1Turn8(&testSubject)
        try player2Turn8_finalTurn(&testSubject)

        #expect(testSubject.game.deck.allCards(for: .one).count == 7)
        #expect(testSubject.game.deck.allCards(for: .two).count == 14)
    }
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

    private func player2Turn2(_ testSubject: inout GameEngine) throws {
        // WHEN - 2up Draws two cards
        // Fish dark blue
        // Ship light blue
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        #expect(
            [
                Card.init(id: 8, kind: .duo(.fish), color: .darkBlue, location: .playerHand(.two)),
                Card.init(id: 9, kind: .duo(.ship), color: .lightBlue, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // Discard fish dark blue to right discard
        // WHEN - 2up discards black fish to right pile
        try testSubject.performAction(.user(.discardToRightPile(8))) // ID of fish
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 8) // ID of Fish
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn3(_ testSubject: inout GameEngine) throws {
        // WHEN - 1up Draws two cards
        // Shark light green
        // Multiplier penguin light green.
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        #expect(
            [
                Card.init(id: 10, kind: .duo(.shark), color: .lightGreen, location: .playerHand(.one)),
                Card.init(id: 11, kind: .multiplier(.penguin), color: .lightGreen, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)


        // WHEN - 1up discards
        // Discard shark light green to left.
        try testSubject.performAction(.user(.discardToLeftPile(10))) // ID of shark

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 10) // ID of Shark
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn3(_ testSubject: inout GameEngine) throws {
        // WHEN - 2up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        // Crab black
        // Ship dark blue
        #expect(
            [
                Card.init(id: 12, kind: .duo(.crab), color: .black, location: .playerHand(.two)),
                Card.init(id: 13, kind: .duo(.ship), color: .darkBlue, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - 2up discards black crab to left
        try testSubject.performAction(.user(.discardToLeftPile(12))) // ID of crab
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 12) // ID of crab
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - Play pair of ships
        let lightBlueShipID = 9
        let darkBLueShipID = 13
        try testSubject.performAction(
            .user(.playEffectWithCards(lightBlueShipID, darkBLueShipID))
        )

        // THEN - Waiting for draw
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)

        // WHEN - Pick up crab black from left discard
        let leftDiscardTopCard = try #require(testSubject.game.deck.topCard(pile: .discardLeft))
        try testSubject.performAction(.user(.pickUpFromLeftDiscard))

        // Black crab is now in player's hand
        #expect(testSubject.game.cardsInHand(ofPlayer: .two).contains(where: {
            $0 == Card(
                id: leftDiscardTopCard.id,
                kind: leftDiscardTopCard.kind,
                color: leftDiscardTopCard.color,
                location: .playerHand(.two)
            )
        }))

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn4(_ testSubject: inout GameEngine) throws {
        // WHEN - 1up Draws two cards
        // Shark light blue
        // Penguin pink
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        #expect(
            [
                Card.init(id: 14, kind: .duo(.shark), color: .lightBlue, location: .playerHand(.one)),
                Card.init(id: 15, kind: .collector(.penguin), color: .lightPink, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)



        // WHEN - 1up discards shark light blue to left
        try testSubject.performAction(.user(.discardToLeftPile(14))) // ID of shark

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 14) // ID of Shark
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn4(_ testSubject: inout GameEngine) throws {
        // WHEN - 2up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        // Fish light green
        // Fish dark blue
        #expect(
            [
                Card.init(id: 16, kind: .duo(.fish), color: .lightGreen, location: .playerHand(.two)),
                Card.init(id: 17, kind: .duo(.fish), color: .darkBlue, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN -  Discard light green fish to left
        try testSubject.performAction(.user(.discardToLeftPile(16))) // ID of crab
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 16) // ID of crab
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - Play pair of crabs
        let lightBlueCrabID = 4
        let blackCrabID = 12
        try testSubject.performAction(
            .user(.playEffectWithCards(lightBlueCrabID, blackCrabID))
        )

        // THEN - Waiting for draw
        #expect(testSubject.game.phase == .resolvingEffect(.pickUpDiscard))
        #expect(testSubject.game.currentPlayerUp == .two)
        #expect(Action<Game>.pickUpFromLeftDiscardPile.rule().validate(on: testSubject.game) == true)

        // WHEN - Pick up light green fish
        try testSubject.performAction(.user(.pickUpFromLeftDiscard))

        // THEN - Light green fish is in 2up hand
        #expect(
            [Card.init(id: 16, kind: .duo(.fish), color: .lightGreen, location: .playerHand(.two)),]
                .allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - Play pair of fish picks up black ship
        let lightGreenFishID = 16
        let darkBlueFishID = 17
        try testSubject.performAction(
            .user(.playEffectWithCards(lightGreenFishID, darkBlueFishID))
        )

        // THEN - Waiting for play and black ship in player hand
        #expect(testSubject.game.phase == .waitingForPlay)
        #expect(testSubject.game.currentPlayerUp == .two)
        #expect(
            [Card.init(id: 18, kind: .duo(.ship), color: .black, location: .playerHand(.two)),]
                .allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn5(_ testSubject: inout GameEngine) throws {
        // 1up
        //
        // WHEN - 1up Draws two cards
        // Fish yellow
        // Sailor pink
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        #expect(
            [
                Card.init(id: 19, kind: .duo(.fish), color: .yellow, location: .playerHand(.one)),
                Card.init(id: 20, kind: .collector(.sailor), color: .lightPink, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard sailor pink to right.
        try testSubject.performAction(.user(.discardToRightPile(20))) // ID of shark

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 20) // ID of Shark
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn5(_ testSubject: inout GameEngine) throws {
        // WHEN - 2up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        // Swimmer yellow
        // Ship black
        #expect(
            [
                Card.init(id: 21, kind: .duo(.swimmer), color: .yellow, location: .playerHand(.two)),
                Card.init(id: 22, kind: .duo(.ship), color: .black, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)


        // WHEN - Discard swimmer yellow to discard left.
        try testSubject.performAction(.user(.discardToLeftPile(21))) // ID of crab
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 21) // ID of crab
        #expect(testSubject.game.phase == .waitingForPlay)

        // Play pair of ships
        // WHEN - Play pair of ships
        let blackShipID1 = 18
        let blackShipID2 = 22
        try testSubject.performAction(
            .user(.playEffectWithCards(blackShipID1, blackShipID2))
        )

        // THEN - Waiting for draw
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)

        // WHEN - 2up Draws two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        // Shark dark blue
        // Swimmer dark blue
        #expect(
            [
                Card.init(id: 23, kind: .duo(.shark), color: .darkBlue, location: .playerHand(.two)),
                Card.init(id: 24, kind: .duo(.swimmer), color: .darkBlue, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)


        // WHEN - Discard dark blue swimmer to right
        try testSubject.performAction(.user(.discardToRightPile(24)))
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 24)
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn6(_ testSubject: inout GameEngine) throws {
        // 1up
        //
        // WHEN - Draw two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        // Fish black
        // Mermaid
        #expect(
            [
                Card.init(id: 25, kind: .duo(.fish), color: .black, location: .playerHand(.one)),
                Card.init(id: 26, kind: .mermaid, color: .white, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard black fish to right
        try testSubject.performAction(.user(.discardToRightPile(25))) // ID of fish

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 25) // ID of fish
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn6(_ testSubject: inout GameEngine) throws {
        // WHEN - Pick up swimmer yellow from left discard
        try testSubject.performAction(.user(.pickUpFromLeftDiscard))

        // THEN - 2up should possess yellow swimmer
        let yellowSwimmerID = 21
        #expect(testSubject.game.phase == .waitingForPlay)
        #expect(
            [Card.init(id: yellowSwimmerID, kind: .duo(.swimmer), color: .yellow, location: .playerHand(.two)),]
                .allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )

        // WHEN - Play steal card
        let darkBlueSharkID = 23
        try testSubject.performAction(
            .user(.playEffectWithCards(darkBlueSharkID, yellowSwimmerID))
        )

        // THEN - Resolving effects
        #expect(testSubject.game.phase == .resolvingEffect(.stealCard))

        // WHEN - Stole yellow fish from 1up
        let yellowFishID = 19
        try testSubject.performAction(.user(.stealCard(yellowFishID)))

        // THEN - Yellow fish should be in 2up hand
        #expect(testSubject.game.phase == .waitingForPlay)
        #expect(
            [Card.init(id: yellowFishID, kind: .duo(.fish), color: .yellow, location: .playerHand(.two)),]
                .allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn7(_ testSubject: inout GameEngine) throws {
        // WHEN - Draw two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        // Shark purple
        // Ship yellow
        #expect(
            [
                Card.init(id: 27, kind: .duo(.shark), color: .purple, location: .playerHand(.one)),
                Card.init(id: 28, kind: .duo(.ship), color: .yellow, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard shark to left discard
        try testSubject.performAction(.user(.discardToLeftPile(27))) // ID of shark

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 27) // ID of shark
        #expect(testSubject.game.phase == .waitingForPlay)

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn7(_ testSubject: inout GameEngine) throws {
        // WHEN - Pick up black fish from right discard
        try testSubject.performAction(.user(.pickUpFromRightDiscard))

        // THEN - 2up should possess black fish
        let blackFishID = 25
        #expect(testSubject.game.phase == .waitingForPlay)
        #expect(
            [Card.init(id: blackFishID, kind: .duo(.fish), color: .black, location: .playerHand(.two)),]
                .allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )

        // WHEN - Play pair of fish
        let yellowFishID = 19
        try testSubject.performAction(.user(.playEffectWithCards(yellowFishID, blackFishID)))

        // THEN - Pick up black shell from draw pile
        #expect(testSubject.game.phase == .waitingForPlay)
        #expect(
            [Card.init(id: 29, kind: .collector(.shell), color: .black, location: .playerHand(.two)),]
                .allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )

        // WHEN - 2up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .one)
    }

    private func player1Turn8(_ testSubject: inout GameEngine) throws {
        // 1up
        //
        // Draw two cards

        // WHEN - Draw two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        // Shell dark blue
        // Crab dark blue
        #expect(
            [
                Card.init(id: 30, kind: .collector(.shell), color: .darkBlue, location: .playerHand(.one)),
                Card.init(id: 31, kind: .duo(.crab), color: .darkBlue, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard crab dark blue to left discard
        try testSubject.performAction(.user(.discardToLeftPile(31))) // ID of crab

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 31) // ID of crab
        #expect(testSubject.game.phase == .waitingForPlay)
        // End turn

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .waitingForDraw)
        #expect(testSubject.game.currentPlayerUp == .two)
    }

    private func player2Turn8_finalTurn(_ testSubject: inout GameEngine) throws {
        // WHEN - Draw two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 2up's hand.
        // Penguin purple
        // Shell yellow
        #expect(
            [
                Card.init(id: 32, kind: .collector(.penguin), color: .purple, location: .playerHand(.two)),
                Card.init(id: 33, kind: .collector(.shell), color: .yellow, location: .playerHand(.two))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .two).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard purple penguin to right
        try testSubject.performAction(.user(.discardToRightPile(32))) // ID of penguin
        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardRight)?.id == 32) // ID of penguin
        #expect(testSubject.game.phase == .waitingForPlay)
    }
    
    private func player1Turn9_lastChanceWon(_ testSubject: inout GameEngine) throws {
        // 1up
        //
        // Draw two cards

        // WHEN - Draw two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        #expect(
            [
                Card.init(id: 34, kind: .collector(.sailor), color: .orange, location: .playerHand(.one)),
                Card.init(id: 35, kind: .multiplier(.sailor), color: .orange, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard crab dark blue to left discard
        try testSubject.performAction(.user(.discardToLeftPile(34))) // ID of sailor

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 34) // ID of sailor
        #expect(testSubject.game.phase == .waitingForPlay)
        // End turn

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .roundEnded(.lastChance))
        #expect(testSubject.game.currentPlayerUp == .two)
    }
    
    private func player1Turn9_lastChanceLost(_ testSubject: inout GameEngine) throws {
        // 1up
        //
        // Draw two cards

        // WHEN - Draw two cards
        try testSubject.performAction(.user(.drawPilePickUp))

        // THEN - Check if the drawn cards are in 1up's hand.
        #expect(
            [
                Card.init(id: 34, kind: .collector(.sailor), color: .orange, location: .playerHand(.one)),
                Card.init(id: 35, kind: .collector(.octopus), color: .lightGreen, location: .playerHand(.one))
            ].allSatisfy(testSubject.game.cardsInHand(ofPlayer: .one).contains(_:))
        )
        #expect(testSubject.game.phase == .waitingForDiscard)

        // WHEN - Discard crab dark blue to left discard
        try testSubject.performAction(.user(.discardToLeftPile(34))) // ID of sailor

        // THEN -
        #expect(testSubject.game.deck.topCard(pile: .discardLeft)?.id == 34) // ID of sailor
        #expect(testSubject.game.phase == .waitingForPlay)
        // End turn

        // WHEN - 1up ends turn
        try testSubject.performAction(.user(.endTurn))

        // THEN - Play is now with player 2
        #expect(testSubject.game.phase == .roundEnded(.lastChance))
        #expect(testSubject.game.currentPlayerUp == .two)
    }
}

extension Array where Element == Card {
    fileprivate static let lastChanceBetWon: Self = [
        .collector(.sailor, id: 34, color: .orange), // Sailor orange - 1up draw
        .multiplier(.sailor, id: 35, color: .orange), // Multiplier Sailor orange - 1up draw
    ]
    
    fileprivate static let lastChanceBetLost: Self = [
        .collector(.sailor, id: 34, color: .orange), // Collector Sailor orange - 1up draw
        .collector(.octopus, id: 35, color: .lightGreen), // Octopus - 1up draw
    ]

    fileprivate static let roundDeck: Self = [
        .duo(.crab, id: 0, color: .lightBlue), // Crab light Blue -> Discard left
        .collector(.shell, id: 1, color: .lightGrey), // Shell Grey -> Discard right
        .collector(.octopus, id: 2, color: .lightGreen), // Octopus light Green (1up draw)
        .duo(.shark, id: 3, color: .black), // Black shark (1up draw)
        .duo(.crab, id: 4, color: .lightBlue), // Crab light blue (2up draw)
        .duo(.fish, id: 5, color: .black), // Black fish (2up draw)
        .mermaid(id: 6), // Mermaid (1up draw)
        .duo(.ship, id: 7, color: .yellow), // Ship yellow (1up draw)
        .duo(.fish, id: 8, color: .darkBlue), // Fish dark blue - 2up draw
        .duo(.ship, id: 9, color: .lightBlue), // Ship light blue - 2up draw
        .duo(.shark, id: 10, color: .lightGreen), // Shark light green - 1up draw
        .multiplier(.penguin, id: 11, color: .lightGreen), // Multiplier penguin light green. - 1up draw
        .duo(.crab, id: 12, color: .black), // Crab black - 2up draw
        .duo(.ship, id: 13, color: .darkBlue), // Ship dark blue - 2up draw
        .duo(.shark, id: 14, color: .lightBlue), // Shark light blue - 1up draw
        .collector(.penguin, id: 15, color: .lightPink), // Penguin pink - 1up draw
        .duo(.fish, id: 16, color: .lightGreen), // Fish light green - 2up draw
        .duo(.fish, id: 17, color: .darkBlue), // Fish dark blue - 2up draw
        .duo(.ship, id: 18, color: .black), // Black ship - 2up fish pick up
        .duo(.fish, id: 19, color: .yellow), // Fish yellow - 1up draw
        .collector(.sailor, id: 20, color: .lightPink), // Sailor pink - 1up draw
        .duo(.swimmer, id: 21, color: .yellow), // Swimmer yellow - 2up draw
        .duo(.ship, id: 22, color: .black), // Ship black - 2up draw
        .duo(.shark, id: 23, color: .darkBlue), // Shark dark blue - 2up draw (ship turn)
        .duo(.swimmer, id: 24, color: .darkBlue), // Swimmer dark blue - 2up draw (ship turn)
        .duo(.fish, id: 25, color: .black), // Fish black - 1up draw
        .mermaid(id: 26), // Mermaid - 1up draw
        .duo(.shark, id: 27, color: .purple), // Shark purple - 1up draw
        .duo(.ship, id: 28, color: .yellow),// Ship yellow - 1up draw
        .collector(.shell, id: 29, color: .black), // 2up fish draw
        .collector(.shell, id: 30, color: .darkBlue), // Shell dark blue
        .duo(.crab, id: 31, color: .darkBlue), // Crab dark blue
        .collector(.penguin, id: 32, color: .purple), // Penguin purple - 2up draw
        .collector(.shell, id: 33, color: .yellow), // Shell yellow - 2up draw
    ]
}

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
