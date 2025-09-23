import Foundation

// MARK: - Command
extension Command where S == Game {
    static func gameCommand(_ command: Command<Game>) -> Self { command }
    static func changePhase(to phase: Game.Phase) -> Self { .init(execute: { $0.phase = phase }) }

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

