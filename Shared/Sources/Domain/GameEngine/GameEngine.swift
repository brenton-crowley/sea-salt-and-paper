import Dependencies
import Foundation
import Models
import SharedDependency
import SharedLogger

public struct GameEngine: Sendable {
    let dataProvider: GameEngine.DataProvider

    private(set) public var game: Game = .placeholder

    private let cards: [Card]
    private let logger = Logger(for: Self.self)

    init(dataProvider: GameEngine.DataProvider) {
        self.dataProvider = dataProvider
        self.cards = dataProvider.deck()
    }
}

// MARK: - Public API
extension GameEngine {
    public mutating func playAction(_ action: GameEngine.Action) throws {
        guard action.validationRule.validate(on: game) else { return } // Maybe throw here

        try action.play(on: &game)
    }
}

// MARK: - Private API
extension GameEngine {
    private mutating func createGame(playersInGameCount: Player.InGameCount) {
        self.game = Game(
            id: dataProvider.newGameID(),
            cards: cards,
            playersInGame: playersInGameCount
        )
    }
}

// MARK: - DependencyModeKey Conformance
extension GameEngine: DependencyModeKey {
    public static let live: GameEngine = .init(dataProvider: .default)

    public static let mock: GameEngine = .init(
        dataProvider: .init(
            deck: { .testMock },
            newGameID: { .init(0) }
        )
    )

    public static let mockError: GameEngine = .init(
        dataProvider: .init(
            deck: { [] },
            newGameID: { .init(0) }
        )
    )
}

// MARK: - Extensions
extension Game {
    static let placeholder: Self = .init(id: .init(0), cards: [], playersInGame: .two)
}

