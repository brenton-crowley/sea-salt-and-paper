import Foundation

extension ThrowingCommand where S == Deck {
    static func drawPilePickUp(player: Player.Up) -> Self {
        .init(
            execute: { deck in
                try deck.draw(pile: .draw)
                    .forEach { deck.update(cardID: $0.id, toLocation: .player(player)) }
            }
        )
    }
}


