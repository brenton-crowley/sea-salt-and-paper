import Foundation
import OrderedCollections

// MARK: - Definition

public struct Deck: Sendable, Hashable {
    public enum Error: Swift.Error, Hashable, Sendable {
        case pileEmpty(Pile)
    }

    private(set) public var cards: OrderedSet<Card> = [] // Source of truth

    public init() {}
}

// MARK: - Computed Properties

extension Deck {
    public var leftDiscardPile: [Card] { cards.filter { $0.location == .pile(.discardLeft) } }
    public var rightDiscardPile: [Card] { cards.filter { $0.location == .pile(.discardRight) } }
    public var drawPile: [Card] { cards.filter({ $0.location == .pile(.draw) }) }

    public func cardsInHand(for player: Player.Up) -> [Card] {
        cards.filter { $0.location == .playerHand(player) }
    }

    public func allCards(for player: Player.Up) -> [Card] {
        cards.filter { $0.location == .playerHand(player) || $0.location == .playerEffects(player) }
    }

    public func topCard(pile: Pile) -> Card? {
        switch pile {
        case .draw: drawPile.first(where: { $0.location == .pile(.draw) })
        case .discardLeft: leftDiscardPile.last // Most recent card drawn and placed here
        case .discardRight: rightDiscardPile.last // Most recent card drawn and placed here
        }
    }

    public func bottomCard(pile: Pile) -> Card? {
        switch pile {
        case .draw: drawPile.last(where: { $0.location == .pile(.draw) })
        case .discardLeft: leftDiscardPile.first // Oldest card drawn and placed here
        case .discardRight: rightDiscardPile.first // Oldest card drawn and placed here
        }
    }
}

// MARK: - Public API Methods

extension Deck {
    public mutating func loadDeck(_ deck: [Card]) {
        cards = OrderedSet(deck)
    }

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

    public mutating func draw(pile: Pile) throws -> Array<Card>.SubSequence {
        switch pile {
        case .draw:
            guard !drawPile.isEmpty else { throw Error.pileEmpty(.draw) }
            return drawPile.prefix(pile.drawNumber)

        case .discardLeft:
            guard !leftDiscardPile.isEmpty else { throw Error.pileEmpty(.discardLeft) }
            return leftDiscardPile.prefix(pile.drawNumber)

        case .discardRight:
            guard !rightDiscardPile.isEmpty else { throw Error.pileEmpty(.discardRight) }
            return rightDiscardPile.prefix(pile.drawNumber)
        }
    }
}

// MARK: - Private API Methods

extension Deck {
    private mutating func updateCard(card: Card, at cardIndex: Int) {
        cards.remove(at: cardIndex)
        cards.insert(card, at: cardIndex)
    }
}

// MARK: - Mocks

#if DEBUG

extension Deck {
    public static func mock() -> Self {
        .init()
    }
}

#endif

