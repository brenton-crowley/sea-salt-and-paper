import Foundation
import Models

extension Action where S == GameEngine {
    static let endTurn: Self = .init(
        rule: .ruleToEndTurn,
        command: .endTurnCommand
    )
}

extension ValidationRule where Input == GameEngine {
    fileprivate static let ruleToEndTurn: Self = .init {
        guard
            GameEngine.Action.User.endTurn.action.rule().validate(on: $0.game)
        else { return false }
        return true
    }
}

extension Command where S == GameEngine {
    // ⚠️ Write a test for there.
    fileprivate static let endTurnCommand: Self = .init {
        // Run the game action
        try GameEngine.Action.User.endTurn.action.command().execute(on: &$0.game)

        // Run the system actions.
        // - Check mermaids
        guard !$0.game.currentPlayerHasFourMermaids else {
            // -- If win, immediately end game
            return // End game
        }

        // -- Change to next player
        $0.game.nextPlayer()
        $0.game.set(phase: .waitingForDraw)
    }
}

extension Game {
    var currentPlayerHasFourMermaids: Bool {
        deck.cards
            .filter { $0.location == .playerHand(currentPlayerUp) }
            .filter { $0.kind == .mermaid }
            .count == 4
    }
}
