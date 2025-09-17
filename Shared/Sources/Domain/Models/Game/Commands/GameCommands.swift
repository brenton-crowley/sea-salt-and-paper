import Foundation

extension ThrowingCommand where S == Game {
    public static func pickUpFromDrawPile(player: Player.Up) -> Self {
        .init { game in
            try ThrowingCommand<Deck>.drawPilePickUp(player: player).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForDiscard).execute(on: &game)
        }
    }
}
