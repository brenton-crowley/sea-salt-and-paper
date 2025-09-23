import Foundation
import Models

// MARK: - Definition

extension ValidationRule where Input == Game {
    static let ruleToPickUpFromDrawPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.drawPile.isEmpty
        else { return false }

        return true
    }

    static let ruleToDrawFromLeftDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.leftDiscardPile.isEmpty
        else { return false }

        return true
    }

    static let ruleToDrawFromRightDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.rightDiscardPile.isEmpty
        else { return false }

        return true
    }

    static func ruleToDiscard(cardID: Card.ID, onto pile: Deck.Pile) -> Self {
        .init { game in
            guard
                game.phase(equals: .waitingForDiscard),
                let card = game.deck.card(id: cardID),
                card.location == .playerHand(game.currentPlayerUp)
            else { return false }

            return ValidationRule<Deck>.canDiscard(to: pile).validate(on: game.deck)
        }
    }
}
