import Foundation
import OrderedCollections

// MARK: - Definition

public struct Deck: Sendable, Hashable {
    private(set) public var cards: OrderedSet<Card> = [] // Source of truth

    public init() {}
}

// MARK: - Computed Properties

extension Deck {
    public var leftDiscardPile: [Card] { cards.filter { $0.location == .pile(.discardLeft) } }

    public var rightDiscardPile: [Card] { cards.filter { $0.location == .pile(.discardRight) } }

    public var drawPile: [Card] { cards.filter({ $0.location == .pile(.draw) }) }

    public func cardsInHand(for player: Player.Up) -> [Card] {
        cards.filter { $0.location == .player(player) }
    }
}

// MARK: - Methods

extension Deck {
    public mutating func loadDeck(_ deck: [Card]) {
        cards = OrderedSet(deck)
    }

    public mutating func shuffle() {
        cards.shuffle()
    }

    // Update the location of a card
    public mutating func update(cardID: Card.ID, toLocation location: Card.Location) {
        guard let cardIndex = cards.firstIndex(where: { $0.id == cardID }) else { return }
        var card = cards[cardIndex]
        card.location = location
        updateCard(card: card, at: cardIndex)
    }

    public func card(id: Card.ID) -> Card? {
        guard let card = cards.first(where: { $0.id == id }) else { return nil }
        return card
    }

    private mutating func updateCard(card: Card, at cardIndex: Int) {
        cards.remove(at: cardIndex)
        cards.insert(card, at: cardIndex)
    }
}

// MARK: - Mocks

#if DEBUG

extension Deck {

}

#endif

