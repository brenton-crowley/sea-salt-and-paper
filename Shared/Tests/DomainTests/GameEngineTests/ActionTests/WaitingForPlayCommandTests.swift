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

struct WaitingForPlayCommandTests {
    @Test("Play Effect - Pair of crabs resolving effect pick up discard")
    func playEffectPairOfCrabs() throws {
        // GIVEN
        let mockCards: [Card] = [
            .duo(.crab, id: 0, location: .playerHand(.one)),
            .duo(.crab, id: 1, location: .playerHand(.one)),
        ]

        var game = Game(id: .mockGameID(), cards: mockCards, playersInGame: .two)
        game.set(phase: .waitingForPlay) // Makes action valid
        let playerCards = mockCards.filter({ $0.location == .playerHand(game.currentPlayerUp) })

        let action = Action<Game>.playEffect(cards: (playerCards[0].id, playerCards[1].id))

        #expect(action.rule().validate(on: game))

        // WHEN
        try action.command().execute(on: &game)

        // THEN
        #expect(game.phase(equals: .resolvingEffect(.pickUpDiscard)))
        #expect(
            game.deck.cards.map(\.location) == [
                .playerEffects(.one),
                .playerEffects(.one),
            ]
        )
    }

    @Test("Play Effect - Pair of Ships restarts player's turn")
    func playEffectPairOfShips() throws {
        // GIVEN
        let mockCards: [Card] = [
            .duo(.ship, id: 2, location: .playerHand(.one)),
            .duo(.ship, id: 3, location: .playerHand(.one)),
        ]

        var game = Game(id: .mockGameID(), cards: mockCards, playersInGame: .two)
        game.set(phase: .waitingForPlay) // Makes action valid
        let playerCards = mockCards.filter({ $0.location == .playerHand(game.currentPlayerUp) })

        let action = Action<Game>.playEffect(cards: (playerCards[0].id, playerCards[1].id))

        #expect(action.rule().validate(on: game))

        // WHEN
        try action.command().execute(on: &game)

        // THEN
        #expect(game.phase(equals: .waitingForDraw))
        #expect(
            game.deck.cards.map(\.location) == [
                .playerEffects(.one),
                .playerEffects(.one),
            ]
        )
    }

    @Test("Play Effect - Pair of Fish pick up first draw pile card")
    func playEffectPairOfFish() throws {
        // GIVEN
        let mockCards: [Card] = [
            .duo(.fish, id: 0, location: .playerHand(.one)),
            .duo(.fish, id: 1, location: .playerHand(.one)),
            .duo(.ship, id: 2, location: .pile(.draw)),
            .duo(.crab, id: 3, location: .pile(.draw)),
        ]

        var game = Game(id: .mockGameID(), cards: mockCards, playersInGame: .two)
        game.set(phase: .waitingForPlay) // Makes action valid
        // Current player is one
        let playerCards = mockCards.filter({ $0.location == .playerHand(game.currentPlayerUp) })

        let action = Action<Game>.playEffect(cards: (playerCards[0].id, playerCards[1].id))

        #expect(action.rule().validate(on: game))

        // WHEN
        try action.command().execute(on: &game)

        // THEN
        #expect(game.phase(equals: .waitingForPlay))
        #expect(
            game.deck.cards.map(\.location) == [
                .playerEffects(.one),
                .playerEffects(.one),
                .playerHand(.one),
                .pile(.draw)
            ]
        )
    }
}

extension Array where Element == Card {
    fileprivate static let duoEffectMock: Self = [
        .duo(.crab, id: 0, location: .playerHand(.one)),
        .duo(.crab, id: 1, location: .playerHand(.one)),
        .duo(.ship, id: 2, location: .playerHand(.two)),
        .duo(.ship, id: 3, location: .playerHand(.two)),
        .duo(.fish, id: 4, location: .pile(.discardLeft)),
        .duo(.fish, id: 5, location: .pile(.discardRight)),
        .duo(.swimmer, id: 6),
        .duo(.shark, id: 7),
    ]

    fileprivate var ids: [Card.ID] { Self.duoEffectMock.map(\.id) }
}
