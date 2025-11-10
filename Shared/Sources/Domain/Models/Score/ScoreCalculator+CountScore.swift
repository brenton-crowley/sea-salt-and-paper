import Foundation

extension ScoreCalculator {
    fileprivate enum DuoScore: Hashable {
        case standard(Card.Duo)
        case swimmerOrShark(Card.Duo)
    }

    struct CountScore: Sendable {
        var scoreForCards: @Sendable (_ cards: [Card]) -> Int
    }
}

// MARK: - Count Score Members
extension ScoreCalculator.CountScore {
    // Score Duo
    // Crab, Fish, Ship pairs all worth 1
    static let duos: Self = .init { cards in
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

    // Collections
    // shell 0, 2, 4, 6, 8
    // octopus 0, 3, 6, 9
    // penguin 1, 3, 5
    // sailor 0, 5
    static let collections: Self = .init { cards in
        let collections = Dictionary(grouping: cards.filterCollections, by: { $0 })

        let collectionScores = collections.compactMap { key, value in
            collections[key].map { key.score(countInCollection: $0.count) }
        }

        return collectionScores.reduce(0, +)
    }

    // Score Multiplier
    // ship x1
    // fish x1
    // penguin x2
    // sailor x3
    static let multipliers: Self = .init { cards in
        let multipliersInCards = cards.filterMultipliers

        let score = multipliersInCards.reduce(0) { score, multiplier in
            score + multiplier.score(for: cards)
        }

        return score
    }

    // Score Mermaids
    // Group colours and count the number in group.
    // For each mermaid, score 1x per card in group
    //
    static let mermaids: Self = .init { cards in
        let colorCounts = Dictionary(grouping: cards.map(\.color), by: { $0 })
            .filter({ $0.key != .white }) // Exclude mermaid colors
            .mapValues { $0.count }
            .sorted { lhs, rhs in lhs.value > rhs.value }

        // get the count of mermaids
        let mermaidCount = cards.filter { $0.kind == .mermaid }.count

        guard mermaidCount > 0 else { return 0 }

        // TODO: AI Refactor color score into a method that can be reused by this context but also in other contexts outside of mermaid such as when calculating last chance.
        // CONTEXT: This method is optimised for mermaids but we should be able to resuse this logic so that we can quickly calculate the logic for the color bonus when
        // calculating for last chance bets.
        let colorScore = (0..<mermaidCount).indices.reduce(0) { score, mermaidIndex in
            guard colorCounts.indices.contains(mermaidIndex) else { return score }
            return score + colorCounts[mermaidIndex].value
        }

        return colorScore
    }
}

// MARK: - fileprivate Extensions
extension ScoreCalculator.DuoScore {
    fileprivate init(_ duoKind: Card.Duo) {
        self = switch duoKind {
        case .fish, .crab, .ship: .standard(duoKind)
        case .swimmer, .shark: .swimmerOrShark(duoKind)
        }
    }

    fileprivate var filterStandard: Bool {
        guard case .standard = self else { return false }
        return true
    }
}

extension Card.Collector {
    fileprivate func score(countInCollection: Int) -> Int {
        switch (self, countInCollection) {
        case (.shell, _) where countInCollection <= 5: (countInCollection - 1) * 2
        case (.octopus, _) where countInCollection <= 6: (countInCollection - 1) * 3
        case (.penguin, 1): 1
        case (.penguin, 2): 3
        case (.penguin, 3): 5
        case (.sailor, 1): 0
        case (.sailor, 2): 5
        default: 0
        }
    }
}

extension Card.Multiplier {
    fileprivate var multiplierValue: Int {
        switch self {
        case .ship: 1
        case .fish: 1
        case .penguin: 2
        case .sailor: 3
        }
    }

    fileprivate var matchingCardKind: Card.Kind {
        switch self {
        case .ship: .duo(.ship)
        case .fish: .duo(.fish)
        case .penguin: .collector(.penguin)
        case .sailor: .collector(.sailor)
        }
    }

    fileprivate func score(for cards: [Card]) -> Int {
        let filteredCards = cards.filter { $0.kind == matchingCardKind }.count * multiplierValue
        return filteredCards
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

    fileprivate var filterCollections: [Card.Collector] {
        self.compactMap { card -> Card.Collector? in
            if case let .collector(kind) = card.kind {
                return kind
            }
            return nil
        }
    }

    fileprivate var filterMultipliers: [Card.Multiplier] {
        self.compactMap { card -> Card.Multiplier? in
            if case let .multiplier(kind) = card.kind {
                return kind
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
