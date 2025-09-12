import Foundation
import OrderedCollections

// MARK: - Definition

public struct Deck: Sendable, Hashable {
    private(set) public var cards: OrderedSet<Card> = [] // Source of truth

    public init() {}
}

// MARK: - Computed Properties

extension Deck {}

// MARK: - Methods

extension Deck {
    public mutating func loadDeck(_ deck: [Card]) {
        cards = OrderedSet(deck)
    }

    public mutating func shuffle() {
        cards.shuffle()
    }
}

// MARK: - Mocks

#if DEBUG

extension Deck {

}

#endif

