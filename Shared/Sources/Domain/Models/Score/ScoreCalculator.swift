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
    
    // TODO: Complete Implementation
    public static func roundPointsForLastChance(cards: OrderedSet<Card>, caller: Player.Up) -> [Player.ID: Int] {
        let stopPoints = Self.roundPointsForStop(cards: cards)
        
        return callerWinsBet(stopPoints: stopPoints, caller: caller)
        ? wonLastChanceCalculation(cards: cards, caller: caller, stopPoints: stopPoints)
        : lostLastChanceCalculation(cards: cards, caller: caller, stopPoints: stopPoints)
    }
    
    // Given rounds, calculate total scores
    public static func totalPoints(rounds: [Game.Round]) -> [Player.ID: Int] {
        rounds.reduce(into: [:]) { totals, round in
            for (playerID, points) in round.points {
                totals[playerID, default: 0] += points
            }
        }
    }
    
    public static func winnerByTotalPoints(rounds: [Game.Round]) -> Player.ID? {
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
}

// MARK: - Private API
extension ScoreCalculator {
    private static func score(playerRound cards: [Card]) -> Int {
        guard !cards.isEmpty else { return 0 }
        
        return [
            CountScore.duos.scoreForCards(cards),
            CountScore.collections.scoreForCards(cards),
            CountScore.multipliers.scoreForCards(cards),
            CountScore.mermaids.scoreForCards(cards)
        ].reduce(0, +)
    }
    
    private static func groupedPlayerCards(allCards: OrderedSet<Card>) -> [Player.ID: [Card]] {
        var cardsByPlayer: [Player.ID: [Card]] = [:]

        for card in allCards {
            switch card.location {
            case
                let .playerHand(playerID),
                let .playerEffects(playerID):
                    cardsByPlayer[playerID, default: []].append(card)

            case .pile: continue
            }
        }
        
        return cardsByPlayer
    }
    
    private static func wonLastChanceCalculation(cards: OrderedSet<Card>, caller: Player.Up, stopPoints: [Player.ID : Int]) -> [Player.ID: Int] {
        let groupedPlayerCards = groupedPlayerCards(allCards: cards)
        let bonuses = groupedPlayerCards.mapValues { CountScore.colorBonus.scoreForCards($0) }
        let allPlayers = Set(stopPoints.keys).union(bonuses.keys)

        var result: [Player.ID: Int] = [:]

        for pid in allPlayers {
            if pid == caller { // Caller scores their round points PLUS the color bonus
                result[pid] = (stopPoints[pid] ?? 0) + (bonuses[pid] ?? 0)
            } else { // All other players ONLY score their color bonus
                result[pid] = (bonuses[pid] ?? 0) // opponents: color bonus only
            }
        }
        return result
    }
    
    private static func lostLastChanceCalculation(cards: OrderedSet<Card>, caller: Player.Up, stopPoints: [Player.ID : Int]) -> [Player.ID: Int] {
        let groupedPlayerCards = groupedPlayerCards(allCards: cards)
        let bonuses = groupedPlayerCards.mapValues { CountScore.colorBonus.scoreForCards($0) }
        let allPlayers = Set(stopPoints.keys).union(bonuses.keys)

        var result: [Player.ID: Int] = [:]

        for pid in allPlayers {
            if pid == caller { // Caller scores their round points PLUS the color bonus
                result[pid] = (bonuses[pid] ?? 0)
            } else { // All other players ONLY score their color bonus
                result[pid] = (stopPoints[pid] ?? 0) // opponents: color bonus only
            }
        }
        return result
    }
    
    /// Caller wins their bet if their round points is greater than or equal to any other player.
    private static func callerWinsBet(stopPoints: [Player.ID: Int], caller: Player.Up) -> Bool {
        let callerPoints = stopPoints[caller] ?? 0
        // Caller wins if their points are >= every opponent’s points
        for (playerID, pts) in stopPoints where playerID != caller {
            if callerPoints < pts { return false }
        }
        return true
    }
}
