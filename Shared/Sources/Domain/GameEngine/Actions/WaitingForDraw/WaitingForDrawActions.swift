import Foundation
import Models

// MARK: - Game Actions
extension Action where S == GameEngine {
    static let pickUpFromDrawPile: Self = .init(
        rule: .ruleToPickUpFromDrawPile,
        command: .pickUpFromDrawPile
    )

    static let pickUpFromLeftDiscardPile: Self = .init(
        rule: .ruleToDrawFromLeftDiscardPile,
        command: .pickUpFromDiscardPile(.discardLeft)
    )

    static let pickUpFromRightDiscardPile: Self = .init(
        rule: .ruleToDrawFromRightDiscardPile,
        command: .pickUpFromDiscardPile(.discardRight)
    )

    static func discardToLeftPile(cardID: Card.ID) -> Self {
        .init(
            rule: .ruleToDiscard(cardID: cardID, onto: .discardLeft),
            command: .discardCard(id: cardID, to: .discardLeft)
        )
    }

    static func discardToRightPile(cardID: Card.ID) -> Self {
        .init(
            rule: .ruleToDiscard(cardID: cardID, onto: .discardRight),
            command: .discardCard(id: cardID, to: .discardRight)
        )
    }
}

// MARK: - Game Validations
extension ValidationRule where Input == GameEngine {
    fileprivate static let ruleToPickUpFromDrawPile: Self = .init { gameEngine in
        guard
            gameEngine.game.phase(equals: .waitingForDraw),
            !gameEngine.game.deck.drawPile.isEmpty
        else { return false }

        return true
    }

    fileprivate static let ruleToDrawFromLeftDiscardPile: Self = .init { gameEngine in
        guard
            gameEngine.game.phase(equals: .waitingForDraw),
            !gameEngine.game.deck.leftDiscardPile.isEmpty
        else { return false }

        return true
    }

    static let ruleToDrawFromRightDiscardPile: Self = .init { gameEngine in
        guard
            gameEngine.game.phase(equals: .waitingForDraw),
            !gameEngine.game.deck.rightDiscardPile.isEmpty
        else { return false }

        return true
    }

    fileprivate static func ruleToDiscard(cardID: Card.ID, onto pile: Deck.Pile) -> Self {
        .init { gameEngine in
            guard
                gameEngine.game.phase(equals: .waitingForDiscard),
                let card = gameEngine.game.deck.card(id: cardID),
                card.location == .playerHand(gameEngine.game.currentPlayerUp)
            else { return false }

            return ValidationRule<Deck>.canDiscard(to: pile).validate(on: gameEngine.game.deck)
        }
    }
}

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

// MARK: - Game Commands
extension Command where S == GameEngine {
    public enum Error: Swift.Error {
        case attemptedDrawPilePickUpFromDiscardPile
    }

    fileprivate static let pickUpFromDrawPile: Self = .init { gameEngine in
        // Draw cards and update card locations
        try gameEngine.game.draw(pile: .draw)
            .forEach { gameEngine.game.update(cardID: $0.id, toLocation: .playerHand(gameEngine.game.currentPlayerUp)) }
        // Change the phase
        gameEngine.game.set(phase: .waitingForDiscard)
    }

    fileprivate static func pickUpFromDiscardPile(_ pile: Deck.Pile) -> Self {
        .init { gameEngine in
            guard pile != .draw else { throw Error.attemptedDrawPilePickUpFromDiscardPile }

            try gameEngine.game.draw(pile: pile)
                .forEach { gameEngine.game.update(cardID: $0.id, toLocation: .playerHand(gameEngine.game.currentPlayerUp)) }

            gameEngine.game.set(phase: .waitingForPlay)
        }
    }

    fileprivate static func discardCard(id: Card.ID, to pile: Deck.Pile) -> Self {
        .init {
            $0.game.update(cardID: id, toLocation: .pile(pile))
            $0.game.set(phase: .waitingForPlay)
        }
    }
}
