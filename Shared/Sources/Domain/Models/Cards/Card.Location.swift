import Foundation

// MARK: - Definition

extension Card {
    public enum Location: Hashable, Sendable {
        case pile(Deck.Pile.ID)
        case playerHand(Player.ID)
        case playerEffects(Player.ID)
    }
}


// MARK: - Computed Properties

extension Card.Collector {}

// MARK: - Mapping

extension Card.Collector {
}

// MARK: - Mocks

#if DEBUG

extension Card.Collector {
}

#endif

