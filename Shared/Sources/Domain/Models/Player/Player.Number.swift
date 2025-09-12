import Foundation

// MARK: - Definition

extension Player {
    public enum Up: Sendable, Hashable, CaseIterable {
        case one, two, three, four
    }

    public enum InGameCount: Sendable, Hashable, CaseIterable {
        case two, three, four
    }
}

extension Player.Up {
    public func next(playersInGame: Player.InGameCount) -> Self {
        let players = Self.allCases.prefix(playersInGame.intValue)
        guard
            let selfIndex = players.firstIndex(of: self),
            players.indices.contains(players.index(after: selfIndex))
        else { return players[0] }

        return players[players.index(after: selfIndex)]
    }
}

extension Player.InGameCount {
    public var intValue: Int {
        switch self {
        case .two: 2
        case .three: 3
        case .four: 4
        }
    }
}
