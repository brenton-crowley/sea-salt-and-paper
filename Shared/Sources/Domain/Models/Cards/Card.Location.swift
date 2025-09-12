import Foundation

// MARK: - Definition

extension Card {
    public enum Location: Hashable, Sendable {
        case draw
        case discard(Pile.ID)
        case player(Player.ID)
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

