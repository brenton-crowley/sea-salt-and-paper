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
        "Scores for two cards",
        arguments: [
            (cards: [Card.duo(.fish), .duo(.crab)], expectedScore: 0),
            (cards: [Card.duo(.crab), .duo(.crab)], expectedScore: 1),
            (cards: [Card.duo(.ship), .duo(.ship)], expectedScore: 1),
            (cards: [Card.duo(.swimmer), .duo(.shark)], expectedScore: 1),
            (cards: [Card.duo(.swimmer), .duo(.swimmer)], expectedScore: 0),
            (cards: [Card.duo(.shark), .duo(.shark)], expectedScore: 0),
            (cards: [Card.duo(.shark), .duo(.ship)], expectedScore: 0),
            (cards: [Card.duo(.swimmer), .duo(.ship)], expectedScore: 0),
            (cards: [Card.duo(.ship), .duo(.crab)], expectedScore: 0),
            (cards: [Card.duo(.ship), .duo(.fish)], expectedScore: 0),
        ]
    )
    func scoresForTwoCards(input: (cards: [Card], expectedScore: Int)) {
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
}
