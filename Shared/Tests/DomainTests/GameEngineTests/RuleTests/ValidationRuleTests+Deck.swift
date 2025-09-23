@testable import GameEngine
import Foundation
import Models
import Testing

struct ValidationRuleDeckTests {
    private func deckRule(_ rule: ValidationRule<Deck>) -> ValidationRule<Deck> { rule }

    @Test("Can discard to left pile")
    func canDiscardToLeftPile() {
        // GIVEN
        let mockCards = Array.testMock
        var deck = Deck()
        deck.loadDeck(mockCards)

        // THEN
        #expect(deckRule(.canDiscard(to: .discardLeft)).validate(on: deck))
        #expect(!deckRule(.canDiscard(to: .draw)).validate(on: deck))

        // WHEN - Move the first card from draw to left discard
        deck.update(cardID: mockCards[0].id, toLocation: .pile(.discardLeft))

        // THEN - Should not be able to discard left
        #expect(!deckRule(.canDiscard(to: .discardLeft)).validate(on: deck))
        #expect(!deckRule(.canDiscard(to: .draw)).validate(on: deck))

        // WHEN - Move the second card from draw to right discard
        deck.update(cardID: mockCards[1].id, toLocation: .pile(.discardRight))

        // THEN - Should be able to discard
        #expect(deckRule(.canDiscard(to: .discardLeft)).validate(on: deck))
        #expect(!deckRule(.canDiscard(to: .draw)).validate(on: deck))
    }

    @Test("Can discard to right pile")
    func canDiscardToRightPile() {
        // GIVEN
        let mockCards = Array.testMock
        var deck = Deck()
        deck.loadDeck(mockCards)

        // THEN
        #expect(deckRule(.canDiscard(to: .discardRight)).validate(on: deck))
        #expect(!deckRule(.canDiscard(to: .draw)).validate(on: deck))

        // WHEN - Move the first card from draw to left discard
        deck.update(cardID: mockCards[0].id, toLocation: .pile(.discardRight))

        // THEN - Should not be able to discard left
        #expect(!deckRule(.canDiscard(to: .discardRight)).validate(on: deck))
        #expect(!deckRule(.canDiscard(to: .draw)).validate(on: deck))

        // WHEN - Move the second card from draw to right discard
        deck.update(cardID: mockCards[1].id, toLocation: .pile(.discardLeft))

        // THEN - Should be able to discard
        #expect(deckRule(.canDiscard(to: .discardRight)).validate(on: deck))
        #expect(!deckRule(.canDiscard(to: .draw)).validate(on: deck))
    }
}
