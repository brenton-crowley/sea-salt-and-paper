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
    public mutating func performAction(_ action: GameEngine.Action) throws {
        guard actionIsPlayable(action) else { return } // Maybe throw here

        switch action {
        case let .user(userAction): try userAction.play(on: &game)
        case let .system(systemAction): try runSystemAction(systemAction)
        }
    }

    public func actionIsPlayable(_ action: GameEngine.Action) -> Bool {
        action.validationRule.validate(on: game)
    }
}

// MARK: - Private API
extension GameEngine {
    private mutating func runSystemAction(_ systemAction: Action.System) throws {
        switch systemAction {
        case let .createGame(players):
            // Should probably save the current game
            // Should bundle this up into a command on game engine
            createGame(playersInGameCount: players)
        case .prepareDeckForPlay: break
        }
    }

    private mutating func createGame(playersInGameCount: Player.InGameCount) {
        saveGame()

        self.game = Game(
            id: dataProvider.newGameID(),
            cards: dataProvider.shuffleCards(cards),
            playersInGame: playersInGameCount
        )

        
    }

    private func saveGame() {
        dataProvider.saveGame(game)
    }
}

// MARK: - DependencyModeKey Conformance
extension GameEngine: DependencyModeKey {
    public static let live: GameEngine = .init(dataProvider: .default)

    public static let mock: GameEngine = .init(
        dataProvider: .init(
            deck: { .testMock },
            newGameID: { .init(0) },
            saveGame: { _ in },
            shuffleCards: { $0 }
        )
    )

    public static let mockError: GameEngine = .init(
        dataProvider: .init(
            deck: { [] },
            newGameID: { .init(0) },
            saveGame: { _ in },
            shuffleCards: { $0 }
        )
    )
}

// MARK: - Extensions
extension Game {
    static let placeholder: Self = .init(id: .init(0), cards: [], playersInGame: .two)
}

