import Foundation

// MARK: - Definition

extension Game {
    public struct Round: Sendable, Hashable, Identifiable {
        public var id: Self { self }
        var players: [Player.ID: Player] = [:]
        var currentPlayerUp: Player.Up = .one
        public var currentPlayer: Player? { players[currentPlayerUp] }
        private(set) var deck: Deck = .init()
    }
}

// MARK: - Computed Properties

extension Game.Round {}

// MARK: - Methods

extension Game.Round {
    mutating func nextPlayer() {
        currentPlayerUp = currentPlayerUp.next(playersInGame: players.values.count.playersInGameCount)
    }
}

// MARK: - fileprivate Extensions
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

extension Game.Round {
}

#endif

