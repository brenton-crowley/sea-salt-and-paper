import Foundation
import Models

// MARK: - Definition

extension ValidationRule {
    public static let ruleToPickUpFromDrawPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.drawPile.isEmpty
        else { return false }

        return true
    }

    public static let ruleToDrawFromLeftDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.leftDiscardPile.isEmpty
        else { return false }

        return true
    }

    public static let ruleToDrawFromRightDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.rightDiscardPile.isEmpty
        else { return false }

        return true
    }

    public static func ruleToDiscard(cardID: Card.ID, onto pile: Deck.Pile) -> Self {
        .init { game in
            guard
                game.phase(equals: .waitingForDiscard),
                let card = game.deck.card(id: cardID),
                card.location == .playerHand(game.currentPlayerUp)
            else { return false }

            return game.deck.canDiscard(to: pile)
        }
    }
}
