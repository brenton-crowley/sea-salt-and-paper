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
    fileprivate enum DuoScore: Hashable {
        case standard(Card.Duo)
        case swimmerOrShark(Card.Duo)

        init(_ duoKind: Card.Duo) {
            self = switch duoKind {
            case .fish, .crab, .ship: .standard(duoKind)
            case .swimmer, .shark: .swimmerOrShark(duoKind)
            }
        }

        var filterStandard: Bool {
            guard case .standard = self else { return false }
            return true
        }
    }

    private func countDuos(round cards: [Card]) -> Int {
        let duoScores = Dictionary(grouping: cards.filterDuos, by: { $0 })
        let standardDuoCounts = duoScores.filter { $0.key.filterStandard }.mapValues { $0.count }
        let swimmerSharkDuoCounts = duoScores.filteredSwimmerSharks.mapValues { $0.count }

        var totalScore = standardDuoCounts.values.reduce(0) { score, duoCountInHand in
            score + duoCountInHand.calculateStandardDuoScore
        }

        // Take the minimum value of swimmers/sharks
        swimmerSharkDuoCounts.values.min().map { totalScore += $0 }

        return totalScore
    }
}

extension Array where Element == Card {
    fileprivate var filterDuos: [ScoreCalculator.DuoScore] {
        self.compactMap { card -> ScoreCalculator.DuoScore? in
            if case let .duo(kind) = card.kind {
                return .init(kind)
            }
            return nil
        }
    }
}

extension Dictionary where Key == ScoreCalculator.DuoScore, Value == [ScoreCalculator.DuoScore] {
    fileprivate var filteredSwimmerSharks: Self {
        [
            .swimmerOrShark(.shark): self[.swimmerOrShark(.shark), default: []],
            .swimmerOrShark(.swimmer): self[.swimmerOrShark(.swimmer), default: []]
        ]
    }
}

extension Int {
    // Score = (count / 2) for each group, summed
    fileprivate var calculateStandardDuoScore: Int {
        Int(Double(Double(self) / 2.0).rounded(.towardZero))
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
