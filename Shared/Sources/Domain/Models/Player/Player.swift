import Foundation

// MARK: - Definition

public struct Player: Sendable, Hashable, Identifiable {
    public let id: Player.Number

    private(set) public var cardsInHand: [Card.ID] = []
}
// MARK: - Computed Properties

extension Player {}

// MARK: - Mapping

extension Player {
}

// MARK: - Mocks

#if DEBUG

extension Player {
    public static func mock(id: Player.Number) -> Self {
        .init(
            id: id
        )
    }
}

#endif

