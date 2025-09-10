import Foundation

// MARK: - Definition

public struct Card: Hashable, Sendable {
    public let id: Int
    public let kind: Card.Kind
    public let color: Card.Color
}

// MARK: - Computed Properties

extension Card {}

// MARK: - Mapping

extension Card {
}

// MARK: - Mocks

#if DEBUG

extension Card {
    public static func mock(
        id: Int = 0,
        kind: Kind = .duo(.crab),
        color: Color = .black
    ) -> Self {
        .init(
            id: id,
            kind: kind,
            color: color
        )
    }
}

extension Array where Element == Card {
    public static let mockGames: Self = [
        .mock(id: 0)
    ]
}

#endif

