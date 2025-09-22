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
    public mutating func playAction(_ action: Game.Action) throws {
        guard case .valid = action.isPlayable(in: game) else { return } // Maybe throw here
        // we can also place a guard in here to make sure that the action can be played.
        switch action {
        case .drawPilePickUp: try playThrowingCommand(.pickUpFromDrawPile())
        case let .discardToLeftPile(cardID): playCommand(.discardToLeftPile(cardID: cardID))
        case let .discardToRightPile(cardID): playCommand(.discardToRightPile(cardID: cardID))
        }
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

    private mutating func playCommand(_ command: Command<Game>) {
        command.execute(on: &game)
    }

    private mutating func playThrowingCommand(_ command: ThrowingCommand<Game>) throws {
        try command.execute(on: &game)
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

extension Game.Action {
    func isPlayable(in game: Game) -> GameEngine.ActionValidation {
        return switch self {
        case .drawPilePickUp: .valid
        case let .discardToRightPile(cardID): .invalid
        case let .discardToLeftPile(cardID): .invalid
        }
    }
}

