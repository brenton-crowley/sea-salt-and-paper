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
            let firstTwoCards = try $0.game.draw(pile: .draw)
            guard
                let firstCard = firstTwoCards.first,
                let secondCard = firstTwoCards.last
            else { return }
            $0.game.update(cardID: firstCard.id, toLocation: .pile(.discardLeft))
            $0.game.update(cardID: secondCard.id, toLocation: .pile(.discardRight))
            $0.game.set(phase: .waitingForDraw)
        }
    }
}
