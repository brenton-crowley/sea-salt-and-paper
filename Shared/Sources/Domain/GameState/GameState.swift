import Foundation
import Models
import SharedDependency

public struct GameState: Sendable {
    public enum PlayerCount: Hashable {
        case two, three, four
    }

    let dataProvider: GameState.DataProvider

    // Players
    // Current player index
    var currentPlayer: Player.Number = .one

    // Deck
        // draw pile
        // firstDiscardPile
        // secondDiscardPile

    // GamePhase

    init(dataProvider: GameState.DataProvider) {
        self.dataProvider = dataProvider
    }
}

// MARK: - Public API
extension GameState {
    mutating func nextPlayer() {
        currentPlayer = currentPlayer.next()
    }
}

extension GameState: DependencyModeKey {
    public static func live(
        players: PlayerCount
    ) -> Self {
        .init(dataProvider: .default)
    }

    public static let live: GameState = .init(dataProvider: .default)

    public static let mock: GameState = .init(
        dataProvider: .init(
            deck: { .mockGames }
        )
    )

    public static let mockError: GameState = .init(
        dataProvider: .init(
            deck: { [] }
        )
    )
}


