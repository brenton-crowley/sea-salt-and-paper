import Foundation

// MARK: - Definition

extension ValidationRule {
    public static let ruleToPickUpFromDrawPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.drawPile.isEmpty
        else { return false }

        return true
    }

    public static let drawFromLeftDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.leftDiscardPile.isEmpty
        else { return false }

        return true
    }

    public static let drawFromRightDiscardPile: Self = .init { game in
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

extension Game {
    
}
