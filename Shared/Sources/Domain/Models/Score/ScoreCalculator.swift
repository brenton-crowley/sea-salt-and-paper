import Foundation

public struct ScoreCalculator: Sendable {
    public static let live: Self = .init()

    public init() {}

    // Received an array of Cards
    public func score(playerRound cards: [Card]) -> Int {
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
