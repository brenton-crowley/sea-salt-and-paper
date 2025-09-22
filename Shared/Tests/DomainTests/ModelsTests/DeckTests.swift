@testable import Models
import Foundation
import Testing

struct DeckTests {
    @Test("Load deck defaults to draw location")
    func loadDeck() {
        // GIVEN
        var deck = Deck()

        // WHEN
        deck.loadDeck(.mockCards())

        // THEN
        #expect(deck.cards.map(\.location).allSatisfy({ $0 == .pile(.draw) }))
    }

    @Test(
        "Update card location",
        arguments: [
            (location: Card.Location.pile(.discardLeft), index: 1),
            (location: .pile(.draw), index: 2),
            (location: .pile(.discardRight), index: 3),
            (location: .playerHand(.one), index: 4),
            (location: .playerHand(.two), index: 5),
            (location: .playerHand(.three), index: 6),
            (location: .playerHand(.four), index: 7)
        ]
    )
    func updateCardLocation(input: (location: Card.Location, index: Int)) throws {
        // GIVEN
        let firstCardID = try #require(Array.mockCards().first(where: { $0.id == input.index })?.id)
        var deck = Deck()
        deck.loadDeck(.mockCards())

        // WHEN
        deck.update(cardID: firstCardID, toLocation: input.location)

        // THEN
        #expect(deck.card(id: firstCardID)?.location == input.location)
    }

    @Test("Draw cards from draw pile")
    func drawCardsFromDrawPile() throws {
        // GIVEN
        var testSubject = Deck()
        testSubject.loadDeck(.mockCards())

        // WHEN
        let cards = try testSubject.draw(pile: .draw)

        // THEN
        #expect(cards.count == 2)
        #expect(cards[0] == Array.mockCards()[0])
        #expect(cards[1] == Array.mockCards()[1])
    }

    @Test("Draw cards from discard piles", arguments: [Deck.Pile.discardLeft, .discardRight])
    func drawCardsFromDrawPile(pile: Deck.Pile) throws {
        // GIVEN
        let mockCards = Array.mockCards()
        let discardLeftCardID = mockCards[0].id
        let discardRightCardID = mockCards[1].id
        var testSubject = Deck()
        testSubject.loadDeck(.mockCards())

        // WHEN
        testSubject.update(cardID: discardLeftCardID, toLocation: .pile(.discardLeft))
        testSubject.update(cardID: discardRightCardID, toLocation: .pile(.discardRight))

        let cards = try testSubject.draw(pile: pile)

        // THEN
        switch pile {
        case .draw: Issue.record("Shouldn't call draw pile")
        case .discardLeft:
            #expect(cards.count == 1)
            #expect(cards[0].id == mockCards.first(where: { $0.id == discardLeftCardID })?.id)
            #expect(cards[0].location == .pile(.discardLeft))

        case .discardRight:
            #expect(cards.count == 1)
            #expect(cards[0].id == mockCards.first(where: { $0.id == discardRightCardID })?.id)
            #expect(cards[0].location == .pile(.discardRight))
        }
    }

    @Test("Error - Draw from empty pile", arguments: [Deck.Pile.draw, .discardLeft, .discardRight])
    func errorWhenDrawingCardsFromEmptyDrawPile(pile: Deck.Pile) throws {
        // GIVEN
        var testSubject = Deck()
        testSubject.loadDeck([])

        #expect(
            throws: Deck.Error.pileEmpty(pile).self,
            performing: {
                _ = try testSubject.draw(pile: pile)
            }
        )
    }

    @Test("Cards in hand for player")
    func cardsInHandsForPlayer() {
        // GIVEN
        let mockCards = Array.mockCards()
        var testSubject = Deck()
        testSubject.loadDeck(mockCards)

        let locations = [
            Card.Location.playerHand(.one),
            .playerHand(.two),
            .playerHand(.three),
            .playerHand(.four),
        ]

        for locationIndex in locations.indices {
            let location = locations[locationIndex]
            let card = mockCards[locationIndex]
            testSubject.update(cardID: card.id, toLocation: location)
        }

        // WHEN
        let playerOneHand = testSubject.cardsInHand(for: .one)
        let playerTwoHand = testSubject.cardsInHand(for: .two)
        let playerThreeHand = testSubject.cardsInHand(for: .three)
        let playerFourHand = testSubject.cardsInHand(for: .four)

        // THEN
        #expect(playerOneHand.count == 1)
        #expect(playerTwoHand.count == 1)
        #expect(playerThreeHand.count == 1)
        #expect(playerFourHand.count == 1)
        #expect(playerOneHand.allSatisfy({ $0.location == .playerHand(.one) }))
        #expect(playerTwoHand.allSatisfy({ $0.location == .playerHand(.two) }))
        #expect(playerThreeHand.allSatisfy({ $0.location == .playerHand(.three) }))
        #expect(playerFourHand.allSatisfy({ $0.location == .playerHand(.four) }))

    }

    @Test("Can discard to left pile")
    func canDiscardToLeftPile() {
        // GIVEN
        let mockCards = Array.mockCards()
        var testSubject = Deck()
        testSubject.loadDeck(mockCards)

        // THEN
        #expect(testSubject.canDiscard(to: .discardLeft))
        #expect(!testSubject.canDiscard(to: .draw))

        // WHEN - Move the first card from draw to left discard
        testSubject.update(cardID: mockCards[0].id, toLocation: .pile(.discardLeft))

        // THEN - Should not be able to discard left
        #expect(!testSubject.canDiscard(to: .discardLeft))
        #expect(!testSubject.canDiscard(to: .draw))

        // WHEN - Move the second card from draw to right discard
        testSubject.update(cardID: mockCards[1].id, toLocation: .pile(.discardRight))

        // THEN - Should be able to discard
        #expect(testSubject.canDiscard(to: .discardLeft))
        #expect(!testSubject.canDiscard(to: .draw))
    }

    @Test("Can discard to right pile")
    func canDiscardToRightPile() {
        // GIVEN
        let mockCards = Array.mockCards()
        var testSubject = Deck()
        testSubject.loadDeck(mockCards)

        // THEN
        #expect(testSubject.canDiscard(to: .discardRight))
        #expect(!testSubject.canDiscard(to: .draw))

        // WHEN - Move the first card from draw to left discard
        testSubject.update(cardID: mockCards[0].id, toLocation: .pile(.discardRight))

        // THEN - Should not be able to discard left
        #expect(!testSubject.canDiscard(to: .discardRight))
        #expect(!testSubject.canDiscard(to: .draw))

        // WHEN - Move the second card from draw to right discard
        testSubject.update(cardID: mockCards[1].id, toLocation: .pile(.discardLeft))

        // THEN - Should be able to discard
        #expect(testSubject.canDiscard(to: .discardRight))
        #expect(!testSubject.canDiscard(to: .draw))
    }
}

extension Array where Element == Card {
    fileprivate static func mockCards(maxCards: Int? = nil) -> Self {
        guard
            let maxCards,
            mockCards.indices.contains(maxCards)
        else { return mockCards }

        return Array(mockCards.prefix(maxCards))
    }

    private static let mockCards: Self = [
        .init(id: 1, kind: .duo(.crab), color: .black),
        .init(id: 2, kind: .duo(.ship), color: .darkBlue),
        .init(id: 3, kind: .duo(.fish), color: .lightGreen),
        .init(id: 4, kind: .duo(.shark), color: .lightOrange),
        .init(id: 5, kind: .duo(.swimmer), color: .lightPink),
        .init(id: 6, kind: .mermaid, color: .white),
        .init(id: 7, kind: .collector(.octopus), color: .black),
        .init(id: 8, kind: .collector(.shell), color: .purple),
        .init(id: 8, kind: .collector(.penguin), color: .yellow),
        .init(id: 9, kind: .collector(.sailor), color: .orange),
        .init(id: 10, kind: .multiplier(.sailor), color: .black),
        .init(id: 11, kind: .multiplier(.fish), color: .yellow),
        .init(id: 12, kind: .multiplier(.penguin), color: .lightOrange),
        .init(id: 13, kind: .multiplier(.ship), color: .lightBlue),
    ]
}
