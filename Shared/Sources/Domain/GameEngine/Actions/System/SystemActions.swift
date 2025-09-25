import Foundation
import Models

// MARK: - GameEngine Actions
extension Action where S == GameEngine {
    static func createGame(players: Player.InGameCount) -> Self {
        .init(
            rule: .ruleToCreateGame,
            command: .createGame(for: players)
        )
    }
}

// MARK: - GameEngine Validations
extension ValidationRule where Input == GameEngine {
    // TODO: Need to define the rules to create game
    // Probably need to have a phase of waitingForGame
    fileprivate static let ruleToCreateGame: Self = .init {
        $0.game.phase(equals: .waitingForStart)
    }
}

// MARK: - GameEngine Commands
extension Command where S == GameEngine {
    fileprivate static func createGame(for players: Player.InGameCount) -> Self {
        .init {
            $0.saveGame()
            $0.game = Game(
                id: $0.dataProvider.newGameID(),
                cards: $0.dataProvider.shuffleCards($0.cards),
                playersInGame: players
            )
        }
    }
}
