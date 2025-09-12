@testable import Models
import Foundation
import Testing

struct DeckTests {
    @Test("Load deck defaults to draw location")
    func loadDeck() {
        // GIVEN
        var deck = Deck()

        // WHEN
        deck.loadDeck(.mock())

        // THEN
        #expect(deck.cards.map(\.location).allSatisfy({ $0 == .pile(.draw) }))
    }

    @Test(
        "Update card location",
        arguments: [
            (location: Card.Location.pile(.discardLeft), index: 1),
            (location: .pile(.draw), index: 2),
            (location: .pile(.discardRight), index: 3),
            (location: .player(.one), index: 4),
            (location: .player(.two), index: 5),
            (location: .player(.three), index: 6),
            (location: .player(.four), index: 7)
        ]
    )
    func updateCardLocation(input: (location: Card.Location, index: Int)) throws {
        // GIVEN
        let firstCardID = try #require(Array.mock().first(where: { $0.id == input.index })?.id)
        var deck = Deck()
        deck.loadDeck(.mock())

        // WHEN
        deck.update(cardID: firstCardID, toLocation: input.location)

        // THEN
        #expect(deck.card(id: firstCardID)?.location == input.location)
    }

    // Write a for the computed properties that filter the piles to ensures they're updated.
}

extension Array where Element == Card {
    fileprivate static func mock(maxCards: Int? = nil) -> Self {
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
