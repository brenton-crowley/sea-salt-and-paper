import Foundation

extension ThrowingCommand where S == Game {
    public static func pickUpFromDrawPile(player: Player.Up) -> Self {
        .init { game in
            try ThrowingCommand<Deck>.drawPilePickUp(player: player).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForDiscard).execute(on: &game)
        }
    }

    public static func player(_ player: Player.Up, discard card: Card.ID, to discardPile: Deck.Pile) -> Self {
        .init { game in
            try ThrowingCommand<Deck>.drawPilePickUp(player: player).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForPlay).execute(on: &game)
        }
    }
}
