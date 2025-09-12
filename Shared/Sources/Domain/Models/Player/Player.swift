import Foundation

// MARK: - Definition

public struct Player: Sendable, Hashable, Identifiable {
    public let id: Player.Up

    private(set) public var cardsInHand: [Card.ID] = []

    public init(id: Player.Up) {
        self.id = id
    }
}
// MARK: - Computed Properties

extension Player {}

// MARK: - Mapping

extension Player {
}

// MARK: - Mocks

#if DEBUG

extension Player {
    public static func mock(id: Player.Up) -> Self {
        .init(
            id: id
        )
    }
}

#endif

