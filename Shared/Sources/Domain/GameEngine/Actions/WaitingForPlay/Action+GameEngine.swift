import Foundation
import Models

extension Action where S == GameEngine {
    static let endTurnNextPlayer: Self = .init(
        rule: .ruleToEndTurn,
        command: .endTurnCommand
    )

    static let endTurnStop: Self = .init(
        rule: .ruleToEndTurn,
        command: .endTurnStopCommand
    )
}

extension ValidationRule where Input == GameEngine {
    fileprivate static let ruleToEndTurn: Self = .init {
        guard
            GameEngine.Action.User.endTurn(.nextPlayer).action.rule().validate(on: $0.game)
        else { return false }
        return true
    }
}

extension Command where S == GameEngine {
    fileprivate static let endTurnCommand: Self = .init {
        // Run the game action
        try GameEngine.Action.User.endTurn(.nextPlayer).action.command().execute(on: &$0.game)

        // Run the system actions.
        // - Check mermaids
        guard !$0.game.currentPlayerHasFourMermaids else {
            $0.game.set(phase: .endGame)
            return // End game
        }

        // -- Change to next player
        $0.game.nextPlayer()
        $0.game.set(phase: .waitingForDraw)
    }

    fileprivate static let endTurnStopCommand: Self = .init {
        $0.game.set(phase: .endRound(.stop))
        // Run the system actions.
        // - Check mermaids
        guard !$0.game.currentPlayerHasFourMermaids else {
            $0.game.set(phase: .endGame)
            return // End game
        }

        // Do other stuff...
        // Count scores
        // Determine round winner
        // set up for next round
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
