import Foundation

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
}

// MARK: - Private API
extension ScoreCalculator {
}
