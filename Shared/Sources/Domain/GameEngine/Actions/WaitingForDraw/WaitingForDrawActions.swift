import Foundation
import Models

// MARK: - Game Actions
extension Action where S == Game {
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
extension ValidationRule where Input == Game {
    fileprivate static let ruleToPickUpFromDrawPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw),
            !game.deck.drawPile.isEmpty
        else { return false }

        return true
    }

    fileprivate static let ruleToDrawFromLeftDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw) || game.phase(equals: .resolvingEffect(.pickUpDiscard)),
            !game.deck.leftDiscardPile.isEmpty
        else { return false }

        return true
    }

    static let ruleToDrawFromRightDiscardPile: Self = .init { game in
        guard
            game.phase(equals: .waitingForDraw) || game.phase(equals: .resolvingEffect(.pickUpDiscard)),
            !game.deck.rightDiscardPile.isEmpty
        else { return false }

        return true
    }

    fileprivate static func ruleToDiscard(cardID: Card.ID, onto pile: Deck.Pile) -> Self {
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
extension Command where S == Game {
    public enum Error: Swift.Error {
        case attemptedDrawPilePickUpFromDiscardPile
    }

    fileprivate static let pickUpFromDrawPile: Self = .init { game in
        // Draw cards and update card locations
        try game.draw(pile: .draw)
            .forEach { game.update(cardID: $0.id, toLocation: .playerHand(game.currentPlayerUp)) }
        // Change the phase
        game.set(phase: .waitingForDiscard)
    }

    fileprivate static func pickUpFromDiscardPile(_ pile: Deck.Pile) -> Self {
        .init { game in
            let card = switch pile {
            case .draw: throw Error.attemptedDrawPilePickUpFromDiscardPile
            case .discardLeft: game.deck.leftDiscardPile.last
            case .discardRight: game.deck.rightDiscardPile.last
            }

            card.map{ game.update(cardID: $0.id, toLocation: .playerHand(game.currentPlayerUp)) }

            game.set(phase: .waitingForPlay)
        }
    }

    fileprivate static func discardCard(id: Card.ID, to pile: Deck.Pile) -> Self {
        .init {
            $0.update(cardID: id, toLocation: .pile(pile))
            $0.set(phase: .waitingForPlay)
        }
    }
}
