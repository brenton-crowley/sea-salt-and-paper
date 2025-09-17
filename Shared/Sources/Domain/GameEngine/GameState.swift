import Foundation
import Models
import SharedDependency
import SharedLogger

public struct GameState: Sendable {
    let dataProvider: GameState.DataProvider

    var players: [Player.ID: Player] = [:]
    var currentPlayerUp: Player.Up = .one

    public var currentPlayer: Player? { players[currentPlayerUp] }

    private(set) public var game: Game = .init(id: 0) // TODO: Must be dynamic
    private(set) var deck: Deck = .init()
    private(set) var phase: Game.Phase = .waitingForDraw

    private let logger = Logger(for: Self.self)

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

    public mutating func playAction(_ action: Game.Action) throws {
        // we can also place a guard in here to make sure that the action can be played.
        switch action {
        case .drawPilePickUp: try playThrowingCommand(.pickUpFromDrawPile(player: currentPlayerUp))
        case let .discardToLeftPile(cardID): playCommand(.discardToLeftPile(cardID: cardID))
        case let .discardToRightPile(cardID): playCommand(.discardToRightPile(cardID: cardID))
        }
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

    private mutating func playCommand(_ command: Command<Game>) {
        command.execute(on: &game)
    }

    private mutating func playThrowingCommand(_ command: ThrowingCommand<Game>) throws {
        try command.execute(on: &game)
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


