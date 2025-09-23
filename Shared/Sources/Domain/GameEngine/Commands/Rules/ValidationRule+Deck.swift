import Models

extension ValidationRule where Input == Deck {
    static func canDiscard(to pile: Deck.Pile) -> Self {
        .init { deck in
            switch pile {
            case .draw: false // Can never discard to draw pile
            case .discardLeft:
                deck.leftDiscardPile.isEmpty
                ? true // If this pile is empty, then yes.
                : !deck.rightDiscardPile.isEmpty // When this pile has cards, only discard when right is empty.

            case .discardRight:
                deck.rightDiscardPile.isEmpty
                ? true // If this pile is empty, then yes.
                : !deck.leftDiscardPile.isEmpty // When this pile has cards, only discard when left is empty.
            }
        }
    }
}
