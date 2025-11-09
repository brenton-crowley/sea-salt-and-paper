import Foundation

// MARK: - Definition

public struct Game: Sendable, Hashable, Identifiable {
    public let id: UUID

    internal(set) public var players: [Player.ID: Player] = [:]
    internal(set) public var deck: Deck = .init()
    internal(set) public var phase: Game.Phase = .waitingForStart
    internal(set) public var currentPlayerUp: Player.Up = .one
    internal(set) public var rounds: [Game.Round] = [] // TODO: AI - This property should track the all the game's rounds and scores of players in each round.

    public init(id: UUID, cards: [Card], playersInGame: Player.InGameCount) {
        self.id = id
        self.deck.loadDeck(cards)
        setupPlayers(playersInGame)
    }
}

// MARK: - Computed Properties

extension Game {
    public var currentPlayer: Player? { players[currentPlayerUp] }

    public var currentPlayerHasFourMermaids: Bool {
        deck.cards
            .filter { $0.location == .playerHand(currentPlayerUp) }
            .filter { $0.kind == .mermaid }
            .count == 4
    }
}

// MARK: - Public Methods

extension Game {
    public var nextPlayerUp: Player.Up {
        currentPlayerUp.next(playersInGame: players.values.count.playersInGameCount)
    }

    public func phase(equals phase: Game.Phase) -> Bool {
        self.phase == phase
    }

    public mutating func setNextPlayerUp() {
        currentPlayerUp = nextPlayerUp
    }

    public mutating func set(phase: Game.Phase) {
        self.phase = phase
    }

    public mutating func draw(pile: Deck.Pile) throws -> Array<Card>.SubSequence {
        try deck.draw(pile: pile)
    }

    public mutating func update(cardID: Card.ID, toLocation location: Card.Location) {
        deck.update(cardID: cardID, toLocation: location)
    }

    public func cardsInHand(ofPlayer player: Player.Up) -> [Card] {
        deck.cardsInHand(for: player)
    }
}

// MARK: - Private API

extension Game {
    private mutating func setupPlayers(_ playersInGameCount: Player.InGameCount) {
        switch playersInGameCount {
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
}

// MARK: - Fileprivate Helper Extensions

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

// MARK: - Mocks

#if DEBUG

extension Game {
    public static func mock(
        id: UUID,
        cards: [Card] = .testMock,
        playersInGame: Player.InGameCount = .two
    ) -> Self {
        .init(
            id: id,
            cards: cards,
            playersInGame: playersInGame
        )
    }

    public static func testMock(id: UUID) -> Self {
        Game.mock(id: id)
    }
}

#endif

