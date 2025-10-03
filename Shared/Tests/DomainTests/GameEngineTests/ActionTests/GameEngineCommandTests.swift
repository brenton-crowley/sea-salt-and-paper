@testable import GameEngine
import Foundation
import Models
import Testing

struct GameEngineCommandTest {
    @Test("Success - End Turn")
    func successPlayerEndsTurn() throws {
        // GIVEN
        var testSubject = GameEngine(
            dataProvider: .testValue(
                cards: [],
                newGameID: .mockGameID()
            )
        )

        // Set up game
        try testSubject.performAction(.system(.createGame(players: .two)))

        let action = Action<GameEngine>.endTurn
        testSubject.game.set(phase: .waitingForPlay)
        #expect(action.rule().validate(on: testSubject) == true)
        #expect(testSubject.game.currentPlayerHasFourMermaids == false)

        // WHEN
        try testSubject.performAction(.user(.endTurn))

        // THEN
        #expect(testSubject.game.currentPlayerUp == .two)
        #expect(testSubject.game.phase == .waitingForDraw)
    }

    @Test("Success - End Turn with 4 mermaids")
    func successPlayerEndsTurnWith4Mermaids() throws {
        // GIVEN
        var testSubject = GameEngine(
            dataProvider: .testValue(
                cards: [
                    .mermaid(id: 1, location: .playerHand(.one)),
                    .mermaid(id: 2, location: .playerHand(.one)),
                    .mermaid(id: 3, location: .playerHand(.one)),
                    .mermaid(id: 4, location: .playerHand(.one)),
                ],
                newGameID: .mockGameID()
            )
        )

        // Set up game
        try testSubject.performAction(.system(.createGame(players: .two)))

        let action = Action<GameEngine>.endTurn
        testSubject.game.set(phase: .waitingForPlay)
        #expect(action.rule().validate(on: testSubject) == true)

        // WHEN
        try testSubject.performAction(.user(.endTurn))

        // THEN
        #expect(testSubject.game.currentPlayerHasFourMermaids == true)
        #expect(testSubject.game.currentPlayerUp == .one)
        #expect(testSubject.game.phase == .endGame)
    }
}
