import Scoring
import Foundation
import Models
import Testing

struct ScoringTests {
    @Test("0 - Empty round")
    func scoreIsZeroWithEmptyRound() {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: [])

        // THEN
        #expect(score == 0)
    }

    @Test(
        "Scores for duo cards",
        arguments: [
            // Two Cards
            (cards: [Card.duo(.fish), .duo(.crab)], expectedScore: 0),
            (cards: [.duo(.crab), .duo(.crab)], expectedScore: 1),
            (cards: [.duo(.ship), .duo(.ship)], expectedScore: 1),
            (cards: [.duo(.swimmer), .duo(.shark)], expectedScore: 1),
            (cards: [.duo(.swimmer), .duo(.swimmer)], expectedScore: 0),
            (cards: [.duo(.shark), .duo(.shark)], expectedScore: 0),
            (cards: [.duo(.shark), .duo(.ship)], expectedScore: 0),
            (cards: [.duo(.swimmer), .duo(.ship)], expectedScore: 0),
            (cards: [.duo(.ship), .duo(.crab)], expectedScore: 0),
            (cards: [.duo(.ship), .duo(.fish)], expectedScore: 0),

            // Three cards
            (cards: [Card.duo(.fish), .duo(.crab), .duo(.fish)], expectedScore: 1),
            (cards: [.duo(.crab), .duo(.crab), .duo(.ship)], expectedScore: 1),
            (cards: [.duo(.ship), .duo(.ship), .duo(.shark)], expectedScore: 1),
            (cards: [.duo(.shark), .duo(.shark), .duo(.swimmer)], expectedScore: 1),
            (cards: [.duo(.shark), .duo(.swimmer), .duo(.swimmer)], expectedScore: 1),
            (cards: [.duo(.crab), .duo(.swimmer), .duo(.swimmer)], expectedScore: 0),
            (cards: [.duo(.crab), .duo(.fish), .duo(.ship)], expectedScore: 0),

            // Four cards
            (cards: [.duo(.crab), .duo(.crab), .duo(.crab), .duo(.crab)], expectedScore: 2),
            (cards: [.duo(.ship), .duo(.ship), .duo(.ship), .duo(.ship)], expectedScore: 2),
            (cards: [.duo(.fish), .duo(.fish), .duo(.fish), .duo(.fish)], expectedScore: 2),
            (cards: [.duo(.shark), .duo(.swimmer), .duo(.shark), .duo(.swimmer)], expectedScore: 2),
            (cards: [.duo(.shark), .duo(.crab), .duo(.shark), .duo(.swimmer)], expectedScore: 1),
            (cards: [.duo(.shark), .duo(.crab), .duo(.crab), .duo(.swimmer)], expectedScore: 2),

            // Three points
            (
                cards: [.duo(.crab), .duo(.crab), .duo(.crab), .duo(.crab), .duo(.crab), .duo(.crab)],
                expectedScore: 3
            ),
        ]
    )
    func scoresForTwoDuoCards(input: (cards: [Card], expectedScore: Int)) {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: input.cards)

        // THEN
        #expect(score == input.expectedScore, "Cards: \(input.cards.map(\.kind))")
    }
}

extension Array where Element == Card {
    fileprivate static let oneCrabPair: Self = [
        .duo(.crab, id: 1),
        .duo(.crab, id: 2)
    ]
}

extension Card {
    fileprivate static func duo(
        _ duo: Duo,
        id: Int = 1,
        color: Card.Color = .black
    ) -> Self {
        .init(
            id: id,
            kind: .duo(duo),
            color: color
        )
    }

    fileprivate static func collector(
        _ collector: Card.Collector,
        id: Int = 1,
        color: Card.Color = .black
    ) -> Self {
        .init(
            id: id,
            kind: .collector(collector),
            color: color
        )
    }
}
