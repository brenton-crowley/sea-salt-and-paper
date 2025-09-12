import Foundation

// MARK: - Definition

public struct Card: Hashable, Sendable, Identifiable {
    public let id: Int
    public let kind: Card.Kind
    public let color: Card.Color

    public var location: Card.Location = .draw

    public init(
        id: Int, 
        kind: Card.Kind,
        color: Card.Color
    ) {
        self.id = id
        self.kind = kind
        self.color = color
    }
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

    public static func duo(
        _ duo: Duo,
        id: Int = 1,
        color: Card.Color = .black
    ) -> Self {
        .init(
            id: id,
            kind: .duo(duo),
            color: color
        )
    }

    public static func collector(
        _ collector: Card.Collector,
        id: Int = 1,
        color: Card.Color = .black
    ) -> Self {
        .init(
            id: id,
            kind: .collector(collector),
            color: color
        )
    }

    public static func multiplier(
        _ multiplier: Card.Multiplier,
        id: Int = 1,
        color: Card.Color = .black
    ) -> Self {
        .init(
            id: id,
            kind: .multiplier(multiplier),
            color: color
        )
    }

    public static func mermaid(id: Int = 1) -> Self {
        .init(
            id: id,
            kind: .mermaid,
            color: .white
        )
    }

    public static func color(
        id: Int = 1,
        kind: Card.Kind = .duo(.crab),
        color: Card.Color
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

