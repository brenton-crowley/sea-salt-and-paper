import Foundation

extension ThrowingCommand where S == Game {
    static func throwingGameCommand(_ command: ThrowingCommand<Game>) -> Self { command }

    public static func pickUpFromDrawPile(player: Player.Up) -> Self {
        .init { game in
            try ThrowingCommand<Deck>.drawPilePickUp(player: player).execute(on: &game.deck)
            Command<Game>.changePhase(to: .waitingForDiscard).execute(on: &game)
        }
    }
}

// MARK: - Command
extension Command where S == Game {
    static func gameCommand(_ command: Command<Game>) -> Self { command }

    public static func discardToLeftPile(cardID: Card.ID) -> Self { discardCard(id: cardID, to: .discardLeft) }
    public static func discardToRightPile(cardID: Card.ID) -> Self { discardCard(id: cardID, to: .discardRight) }
}

// MARK: - Private Static API
extension Command where S == Game {
    private static func discardCard(id: Card.ID, to pile: Deck.Pile) -> Self {
        .init {
            $0.deck.update(cardID: id, toLocation: .pile(pile))
            gameCommand(.changePhase(to: .waitingForPlay)).execute(on: &$0)
        }
    }
}

