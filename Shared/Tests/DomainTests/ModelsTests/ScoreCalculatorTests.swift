@testable import Models
import Foundation
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
    func scoresForDuoCards(input: (cards: [Card], expectedScore: Int)) {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: input.cards)

        // THEN
        #expect(score == input.expectedScore, "Cards: \(input.cards.map(\.kind))")
    }

    @Test(
        "Scores for collection cards",
        arguments: [
            // Single Card
            (cards: [Card.collector(.octopus)], expectedScore: 0),
            (cards: [.collector(.shell)], expectedScore: 0),
            (cards: [.collector(.penguin)], expectedScore: 1),
            (cards: [.collector(.sailor)], expectedScore: 0),

            // Two Cards
            (cards: [.collector(.octopus), .collector(.octopus)], expectedScore: 3),
            (cards: [.collector(.shell), .collector(.shell)], expectedScore: 2),
            (cards: [.collector(.penguin), .collector(.penguin)], expectedScore: 3),
            (cards: [.collector(.sailor), .collector(.sailor)], expectedScore: 5),

            // Three Cards
            (cards: [.collector(.octopus), .collector(.octopus), .collector(.octopus)], expectedScore: 6),
            (cards: [.collector(.shell), .collector(.shell), .collector(.shell)], expectedScore: 4),
            (cards: [.collector(.penguin), .collector(.penguin), .collector(.penguin)], expectedScore: 5),

            // Four Cards
            (cards: [.collector(.octopus), .collector(.octopus), .collector(.octopus), .collector(.octopus)],
            expectedScore: 9),
            (cards: [.collector(.shell), .collector(.shell), .collector(.shell), .collector(.shell)],
             expectedScore: 6),

            // Five Cards
            (cards: [.collector(.octopus), .collector(.octopus), .collector(.octopus), .collector(.octopus), .collector(.octopus)],
            expectedScore: 12),
            (cards: [.collector(.shell), .collector(.shell), .collector(.shell), .collector(.shell), .collector(.shell)],
             expectedScore: 8),

            // Combinations
            (cards: [.collector(.octopus), .collector(.octopus), .collector(.shell)], expectedScore: 3),
            (cards: [.collector(.shell), .collector(.shell), .collector(.octopus)], expectedScore: 2),
            (cards: [.collector(.penguin), .collector(.penguin), .collector(.sailor)], expectedScore: 3),
            (cards: [.collector(.sailor), .collector(.sailor), .collector(.penguin)], expectedScore: 6),
            (cards: [
                .collector(.sailor), .collector(.sailor), // 5
                .collector(.penguin), .collector(.penguin), .collector(.penguin), // 5
                .collector(.octopus), .collector(.octopus), .collector(.octopus), .collector(.octopus), .collector(.octopus), // 12
                .collector(.shell), .collector(.shell), .collector(.shell), .collector(.shell), .collector(.shell) // 8
            ],
             expectedScore: 30),
        ]
    )
    func scoresForCollectionCards(input: (cards: [Card], expectedScore: Int)) {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: input.cards)

        // THEN
        #expect(score == input.expectedScore, "Cards: \(input.cards.map(\.kind))")
    }

    @Test(
        "Scores for multiplier cards",
        arguments: [
            // Zero multipliers
            (cards: [Card.multiplier(.fish)], expectedScore: 0),
            (cards: [.multiplier(.penguin)], expectedScore: 0),
            (cards: [.multiplier(.ship)], expectedScore: 0),
            (cards: [.multiplier(.sailor)], expectedScore: 0),

            // Single multipliers
            (cards: [Card.multiplier(.fish), .duo(.fish)], expectedScore: 1),
            (cards: [.multiplier(.ship), .duo(.ship)], expectedScore: 1),
            (cards: [.multiplier(.penguin), .collector(.penguin)], expectedScore: 3), // One for penguin card as well
            (cards: [.multiplier(.sailor), .collector(.sailor)], expectedScore: 3),

            // Two card multipliers
            (cards: [Card.multiplier(.fish), .duo(.fish), .duo(.fish)], expectedScore: 3), // Point for fish pair as well
            (cards: [.multiplier(.ship), .duo(.ship), .duo(.ship)], expectedScore: 3), // Point ship fish pair as well
            (cards: [.multiplier(.penguin), .collector(.penguin), .collector(.penguin)], expectedScore: 7), // One for penguin card as well
            (cards: [.multiplier(.sailor), .collector(.sailor), .collector(.sailor)], expectedScore: 11),
        ]
    )
    func scoresForMultiplierCards(input: (cards: [Card], expectedScore: Int)) {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: input.cards)

        // THEN
        #expect(score == input.expectedScore, "Cards: \(input.cards.map(\.kind))")
    }

    @Test(
        "Scores for mermaid cards",
        arguments: [
            // Single Mermaid
            (cards: [Card.mermaid()], expectedScore: 0),
            (cards: [.mermaid(), .color(color: .black)], expectedScore: 1),
            (cards: [.mermaid(), .color(kind: .duo(.fish), color: .black), .color(kind: .duo(.crab), color: .black)],
             expectedScore: 2),
            (cards: [.mermaid(), .color(kind: .duo(.fish), color: .black), .color(kind: .duo(.crab), color: .black), .color(kind: .duo(.ship), color: .black)],
             expectedScore: 3),

            // Two Mermaids
            (cards: [
                Card.mermaid(), .mermaid(),
                .color(kind: .collector(.octopus), color: .black), .color(kind: .duo(.crab), color: .black), .color(kind: .duo(.fish), color: .black), .color(kind: .duo(.ship), color: .black), // 4 black
                .color(kind: .collector(.sailor), color: .yellow), .color(kind: .multiplier(.penguin), color: .yellow), .color(kind: .collector(.shell), color: .yellow), // 3 yellow
            ],
             expectedScore: 7
            ),

            // Three Mermaids
            (cards: [
                Card.mermaid(), .mermaid(), .mermaid(),
                .color(kind: .collector(.octopus), color: .black), // 1 Black
                .color(kind: .duo(.crab), color: .darkBlue), .color(kind: .duo(.fish), color: .darkBlue), .color(kind: .duo(.ship), color: .darkBlue), // 3 dark blue
                .color(kind: .collector(.sailor), color: .yellow), .color(kind: .multiplier(.penguin), color: .yellow), // 2 yellow
            ],
             expectedScore: 6
            ),
        ]
    )
    func scoresForMermaidCards(input: (cards: [Card], expectedScore: Int)) {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: input.cards)

        // THEN
        #expect(score == input.expectedScore, "Cards: \(input.cards.map(\.kind))")
    }

    @Test(
        "Scores for hand combinations",
        arguments: [
            (cards: [Card.duo(.fish), .duo(.fish), .multiplier(.fish)], expectedScore: 3), // 0 + 1 + 2
            (cards: [.collector(.penguin), .duo(.fish), .multiplier(.penguin)], expectedScore: 3), // 1 + 0 + 2
            (cards: [.collector(.sailor), .collector(.sailor), .duo(.crab), .duo(.crab), .multiplier(.sailor)], expectedScore: 12), // 0 + 5 + 0 + 1 + 6
            (cards: [.collector(.sailor), .collector(.sailor), .duo(.crab), .duo(.crab), .multiplier(.sailor), .mermaid(), .mermaid()], expectedScore: 17), // 0 + 5 + 0 + 1 + 6 + 5 + 0
            (cards: [.collector(.sailor, color: .lightPink), .collector(.sailor, color: .lightOrange), .duo(.crab), .duo(.crab), .multiplier(.sailor), .mermaid(), .mermaid()], expectedScore: 16), // 0 + 5 + 0 + 1 + 6 + 3 + 1
        ]
    )
    func scoresForHandCombinations(input: (cards: [Card], expectedScore: Int)) {
        // GIVEN
        let testSubject = ScoreCalculator()

        // WHEN
        let score = testSubject.score(playerRound: input.cards)

        // THEN
        #expect(score == input.expectedScore, "Cards: \(input.cards.map(\.kind))")
    }
    
    @Test("Total Points Tests")
    func totalPointsTests() async throws {
        // GIVEN
        let rounds: [Game.Round] = .twoPlayersPlayerOneWins
        
        // WHEN
        let totalPoints = ScoreCalculator.totalPoints(rounds: rounds)
        let winner = ScoreCalculator.winner(rounds: rounds)
        
        // THEN
        #expect(totalPoints[.one] == 40)
        #expect(totalPoints[.two] == 38)
        #expect(winner == .one)
    }
    
    @Test("Both players tie, but player one has most recent highest score and is winner")
    func tieWithPlayerOneWinnerOnCountback() async throws {
        // GIVEN
        let rounds: [Game.Round] = [
            .init(state: .complete, points: [.one: 32, .two: 33]),
            .init(state: .complete, points: [.one: 3, .two: 2]),
            .init(state: .complete, points: [.one: 5, .two: 5]),
        ]
        
        // WHEN
        let totalPoints = ScoreCalculator.totalPoints(rounds: rounds)
        let winner = ScoreCalculator.winner(rounds: rounds)
        
        // THEN
        #expect(totalPoints[.one] == 40)
        #expect(totalPoints[.two] == 40)
        #expect(winner == .one)
    }
    
    @Test("Both players tie, players tied whole match")
    func tieNoBreaker() async throws {
        // GIVEN
        let rounds: [Game.Round] = [
            .init(state: .complete, points: [.one: 33, .two: 33]),
            .init(state: .complete, points: [.one: 2, .two: 2]),
            .init(state: .complete, points: [.one: 5, .two: 5]),
        ]
        
        // WHEN
        let totalPoints = ScoreCalculator.totalPoints(rounds: rounds)
        let winner = ScoreCalculator.winner(rounds: rounds)
        
        // THEN
        #expect(totalPoints[.one] == 40)
        #expect(totalPoints[.two] == 40)
        #expect(winner == nil)
    }
    
    @Test("Both players tie, player two come from behind in last round")
    func tiePlayerTwoWinsLastRoundHigherScore() async throws {
        // GIVEN
        let rounds: [Game.Round] = [
            .init(state: .complete, points: [.one: 33, .two: 32]),
            .init(state: .complete, points: [.one: 6, .two: 6]),
            .init(state: .complete, points: [.one: 4, .two: 5]), // Higher score
        ]
        
        // WHEN
        let totalPoints = ScoreCalculator.totalPoints(rounds: rounds)
        let winner = ScoreCalculator.winner(rounds: rounds)
        
        // THEN
        #expect(totalPoints[.one] == 43)
        #expect(totalPoints[.two] == 43)
        #expect(winner == .two)
    }
}

extension Game.Round {
    fileprivate static let twoPlayersRound1: Self = .init(
        state: .complete,
        points: [.one: 3, .two: 7]
    )
    
    fileprivate static let twoPlayersRound2: Self = .init(
        state: .complete,
        points: [.one: 7, .two: 3]
    )
    
    fileprivate static let twoPlayersRound3: Self = .init(
        state: .complete,
        points: [.one: 11, .two: 9]
    )
    
    fileprivate static let twoPlayersRound4: Self = .init(
        state: .complete,
        points: [.one: 14, .two: 12]
    )
    
    fileprivate static let twoPlayersRound5: Self = .init(
        state: .complete,
        points: [.one: 5, .two: 7]
    )
}

extension Array where Element == Game.Round {
    fileprivate static let twoPlayersPlayerOneWins: Self = [
        .twoPlayersRound1, .twoPlayersRound2, .twoPlayersRound3, .twoPlayersRound4, .twoPlayersRound5
    ]
}
