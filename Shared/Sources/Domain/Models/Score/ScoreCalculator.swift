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
    
    // Given rounds, calculate total scores
    public static func totalPoints(rounds: [Game.Round]) -> [Player.ID: Int] {
        rounds.reduce(into: [:]) { totals, round in
            for (playerID, points) in round.points {
                totals[playerID, default: 0] += points
            }
        }
    }
    
    public static func winner(rounds: [Game.Round]) -> Player.ID? {
        // TODO: Check if any player has four mermaids in their hand
        
        // 1) Determine threshold from player count
        guard
            let playerCount = rounds.first?.points.keys.count,
            let numPlayers = Player.InGameCount(count: playerCount) else { return nil }

        // 2) Totals across all rounds
        let totals = ScoreCalculator.totalPoints(rounds: rounds)

        // 3) Require that the top total reaches the threshold
        guard let maxTotal = totals.values.max(), maxTotal >= numPlayers.winningPointsThreshold else {
            return nil
        }

        // 4) Candidates are those tied for the top total
        var candidates = totals.filter { $0.value == maxTotal }.map { $0.key }
        if candidates.count == 1 { return candidates.first }

        // 5) Tie-breaker: scan rounds from latest to earliest
        for round in rounds.reversed() {
            let maxRound = candidates.map { round.points[$0] ?? 0 }.max() ?? 0
            let leaders = candidates.filter { (round.points[$0] ?? 0) == maxRound }
            if leaders.count == 1 { return leaders.first }
            candidates = leaders
        }

        // 6) Still tied after all rounds
        return nil
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
