import Foundation

// MARK: - Definition

public struct Game: Sendable, Hashable, Identifiable {
    public let id: Int
}

// MARK: - Computed Properties

extension Game {}

// MARK: - Mapping

extension Game {
}

// MARK: - Mocks

#if DEBUG

extension Game {
    public static func mock(id: Int) -> Self {
        .init(
            id: id
        )
    }
}

#endif

