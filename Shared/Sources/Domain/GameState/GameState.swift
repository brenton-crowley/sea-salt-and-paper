import Foundation
import Models
import SharedDependency

public struct GameState: Sendable {
    let dataProvider: GameState.DataProvider

    var players: [Player.ID: Player] = [:]
    var currentPlayerUp: Player.Up = .one

    public var currentPlayer: Player? { players[currentPlayerUp] }

    private(set) var deck: Deck = .init()
    private(set) var phase: Game.Phase = .waitingForDraw

    init(dataProvider: GameState.DataProvider) {
        self.dataProvider = dataProvider
        setupDeck()
        setupPlayers()
    }
}

// MARK: - Public API
extension GameState {
    mutating func nextPlayer() {
        currentPlayerUp = currentPlayerUp.next(playersInGame: players.values.count.playersInGameCount)
    }
}

// MARK: - Private API
extension GameState {
    private mutating func setupPlayers() {
        switch dataProvider.playersInGameCount() {
        case .four:
            players[.four] = Player(id: .four)
            fallthrough

        case .three:
            players[.three] = Player(id: .three)
            fallthrough

        case .two:
            players[.two] = Player(id: .two)
            players[.one] = Player(id: .one)
        }
    }

    private mutating func setupDeck() {
        deck.loadDeck(dataProvider.deck())
    }
}

extension Int {
    fileprivate var playersInGameCount: Player.InGameCount {
        switch self {
        case 2: .two
        case 3: .three
        case 4: .four
        default: .two
        }
    }
}

extension GameState: DependencyModeKey {
    public static func live(
        players: Player.InGameCount
    ) -> Self {
        .init(
            dataProvider: .make(
                deckRepository: .live,
                playersInGameCount: players
            )
        )
    }

    public static let live: GameState = .init(dataProvider: .default)

    public static let mock: GameState = .init(
        dataProvider: .init(
            deck: { .mockGames },
            playersInGameCount: { .two }
        )
    )

    public static let mockError: GameState = .init(
        dataProvider: .init(
            deck: { [] },
            playersInGameCount: { .two }
        )
    )
}


