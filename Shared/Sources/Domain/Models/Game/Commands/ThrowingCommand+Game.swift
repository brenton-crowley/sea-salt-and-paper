import Foundation

extension ThrowingCommand where S == Game {
    static func throwingGameCommand(_ command: ThrowingCommand<Game>) -> Self { command }

    public static func pickUpFromDrawPile() -> Self {
        .init { game in
            try ThrowingCommand<Deck>.drawPilePickUp(player: game.currentPlayerUp).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForDiscard).execute(on: &game)
        }
    }

    public static func pickUpFromDiscardLeftPile() -> Self {
        .init { game in
            try ThrowingCommand<Deck>.discardPilePickUp(.discardLeft, player: game.currentPlayerUp).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForPlay).execute(on: &game)
        }
    }

    public static func pickUpFromDiscardRightPile() -> Self {
        .init { game in
            try ThrowingCommand<Deck>.discardPilePickUp(.discardRight, player: game.currentPlayerUp).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForPlay).execute(on: &game)
        }
    }
}
