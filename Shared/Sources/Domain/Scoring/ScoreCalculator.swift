import Foundation
import Models

public struct ScoreCalculator: Sendable {
    public static let live: Self = .init()

    public init() {}

    // Received an array of Cards
    public func score(playerRound cards: [Card]) -> Int {
        guard !cards.isEmpty else { return 0 }

        return countDuos(round: cards)
    }
}

// MARK: - Private API
extension ScoreCalculator {
    private func countDuos(round cards: [Card]) -> Int {
        let counts = Dictionary(
            grouping: cards.filterDuos,
            by: { $0 }
        ).mapValues { $0.count }
        // Need to account for the swimmer and shark combo

        // Score = (count / 2) for each group, summed
        let totalScore = counts.values.reduce(0) { partial, count in
            partial + Double(Double(count) / 2.0).rounded(.towardZero)
        }

        return Int(totalScore)
    }
}

extension Array where Element == Card {
    fileprivate var filterDuos: [Card.Duo] {
        self.compactMap { card -> Card.Duo? in
            if case let .duo(kind) = card.kind { return kind }
            return nil
        }
    }
}
// Score Duo
// Crab, Fish, Ship pairs all worth 1

// Collections
// shell 0, 2, 4, 6, 8
// octopus 0, 3, 6, 9
// penguin 1, 3, 5
// sailor 0, 5

// Score Multiplier
// ship x1
// fish x1
// penguin x2
// sailor x3

// Score Mermaids
// Group colours and count the number in group.
// For each mermaid, score 1x per card in group
//
