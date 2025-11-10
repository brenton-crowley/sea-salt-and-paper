import Foundation
import OrderedCollections

public struct ScoreCalculator: Sendable {
    public static let live: Self = .init()
    
    public init() {}
    
    // TODO: AI  Context - These are stop calculations only
    public func score(playerRound cards: [Card]) -> Int {
        guard !cards.isEmpty else { return 0 }
        
        return [
            CountScore.duos.scoreForCards(cards),
            CountScore.collections.scoreForCards(cards),
            CountScore.multipliers.scoreForCards(cards),
            CountScore.mermaids.scoreForCards(cards)
        ].reduce(0, +)
    }
    
    // TODO: AI - Add ways to calculate scores for a last chance situation.
    public static func roundPointsForStop(cards: OrderedSet<Card>) -> [Player.ID: Int] {
        let cardsByPlayer: [Player.ID: [Card]] = cards.reduce(into: [:]) { result, card in
            switch card.location {
            case .pile: break
            case
                let .playerHand(playerID),
                let .playerEffects(playerID):
                result[playerID, default: []].append(card)
            }
        }
        
        return cardsByPlayer.mapValues { Self.score(playerRound: $0) }
    }
    
    private static func score(playerRound cards: [Card]) -> Int {
        guard !cards.isEmpty else { return 0 }
        
        return [
            CountScore.duos.scoreForCards(cards),
            CountScore.collections.scoreForCards(cards),
            CountScore.multipliers.scoreForCards(cards),
            CountScore.mermaids.scoreForCards(cards)
        ].reduce(0, +)
    }
}

// MARK: - Private API
extension ScoreCalculator {
}

extension Player.InGameCount {
    public var winningPointsThreshold: Int {
        switch self {
        case .two: 40
        case .three: 35
        case .four: 30
        }
    }
}
