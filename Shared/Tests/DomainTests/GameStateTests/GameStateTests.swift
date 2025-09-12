@testable import GameState
import Testing

struct GameStateTests {
    @Test("Cycle through players")
    func nextPlayerChangesCurrentPlayer() async throws {
        // GIVEN
        var testSubject = GameState(dataProvider: .testValue)
        #expect(testSubject.currentPlayer == .one)

        testSubject.nextPlayer()
        #expect(testSubject.currentPlayer == .two)

        testSubject.nextPlayer()
        #expect(testSubject.currentPlayer == .three)

        testSubject.nextPlayer()
        #expect(testSubject.currentPlayer == .four)

        testSubject.nextPlayer()
        #expect(testSubject.currentPlayer == .one)
    }
}
