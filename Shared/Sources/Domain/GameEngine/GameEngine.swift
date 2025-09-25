import Dependencies
import Foundation
import Models
import SharedDependency
import SharedLogger

public struct GameEngine: Sendable {
    let dataProvider: GameEngine.DataProvider

    internal(set) public var game: Game = .placeholder

    let cards: [Card]

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
        case let .user(user): try user.action.command().execute(on: &game)
        case let .system(system): try system.action.command().execute(on: &self)
        }
    }

    public func actionIsPlayable(_ action: GameEngine.Action) -> Bool {
        switch action {
        case let .user(user): user.action.rule().validate(on: game)
        case let .system(system): system.action.rule().validate(on: self)
        }
    }
}

// MARK: - Internal/Private API
extension GameEngine {
    func saveGame() {
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

