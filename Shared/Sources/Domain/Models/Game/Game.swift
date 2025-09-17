import Foundation

// MARK: - Definition

public struct Game: Sendable, Hashable, Identifiable {
    public let id: Int

    var deck: Deck = .init()
    var phase: Game.Phase = .waitingForDraw

    public init(id: Int, deck: Deck = .init(), phase: Game.Phase = .waitingForDraw) {
        self.id = id
        self.deck = deck
        self.phase = phase
    }
}

// MARK: - Computed Properties

extension Game {
}

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

    public static func testMock(id: Int = 0) -> Self {
        var game = Self(id: id)
        game.deck.loadDeck(.testMock)
        return game
    }
}

#endif

