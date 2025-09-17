import Foundation

// MARK: - Definition

public struct Game: Sendable, Hashable, Identifiable {
    public let id: Int

    var deck: Deck = .init()
    var phase: Game.Phase = .waitingForDraw
}

// MARK: - Computed Properties

extension Game {}

// MARK: - Methods

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

