import Foundation

// MARK: - Definition

extension Game {
    public enum Action: Sendable, Hashable, Identifiable {
        case drawPilePickUp
        case discardToRightPile(Card.ID)
        case discardToLeftPile(Card.ID)

        public var id: Self { self }
    }
}

// MARK: - Computed Properties

extension Game.Action {}

// MARK: - Mapping

extension Game.Action {
}

// MARK: - Mocks

#if DEBUG

extension Game.Action {
}

#endif

