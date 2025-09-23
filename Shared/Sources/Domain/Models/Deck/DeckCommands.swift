import Foundation

extension ThrowingCommand where S == Deck {
    public enum Error: Swift.Error {
        case attemptedDrawPilePickUpFromDiscardPile
    }

    static func drawPilePickUp(player: Player.Up) -> Self {
        .init(
            execute: { deck in
                try deck.draw(pile: .draw)
                    .forEach { deck.update(cardID: $0.id, toLocation: .playerHand(player)) }
            }
        )
    }

    static func discardPilePickUp(_ pile: Deck.Pile, player: Player.Up) -> Self {
        .init(
            execute: { deck in
                guard pile != .draw else { throw Error.attemptedDrawPilePickUpFromDiscardPile }

                try deck.draw(pile: pile)
                    .forEach { deck.update(cardID: $0.id, toLocation: .playerHand(player)) }
            }
        )
    }
}


