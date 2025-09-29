import Foundation
import Models

// MARK: - Game Actions
extension Action where S == GameEngine {
    static func playEffect(cards: (Card.ID, Card.ID)) -> Self {
        .init(
            rule: .ruleToPlayEffect(cards: cards),
            command: .playEffect(cards: cards)
        )
    }

    static func stealCard(cardID: Card.ID) -> Self {
        .init(
            rule: .ruleToStealCard(cardID: cardID),
            command: .stealCard(cardID: cardID)
        )
    }
}

// MARK: - Game Validations
extension ValidationRule where Input == GameEngine {
    static func ruleToPlayEffect(cards: (Card.ID, Card.ID)) -> Self {
        .init {
            guard
                $0.game.phase(equals: .waitingForPlay),
                let (firstCard, secondCard) = $0.effectCards(cardIDs: cards)
            else { return false }

            // TODO: Probably need more granular control over these.
            // For example, can only pick up from discard pile if cards available
            // But then, you should be able to play an effect without being able to pick up so as not to have a card stolen from you.
            return switch (firstCard.kind, secondCard.kind) {
            case (.duo(.crab), .duo(.crab)),
                (.duo(.fish), .duo(.fish)),
                (.duo(.ship), .duo(.ship)),
                (.duo(.shark), .duo(.swimmer)),
                (.duo(.swimmer), .duo(.shark)): true
           
            default: false
            }
        }
    }

    fileprivate static func ruleToStealCard(cardID: Card.ID) -> Self {
        .init {
            guard
                let card = $0.game.deck.cards.first(where: { $0.id == cardID }),
                case .playerHand = card.location
            else { return false }
            return true
        }
    }

    fileprivate static let hasPairOfCrabs: Self = .init {
        ValidationRule<Deck>.hasAtLeastTwo(duo: .crab, inHandOfPlayer: $0.game.currentPlayerUp)
            .validate(on: $0.game.deck)
    }
}

extension ValidationRule where Input == Deck {
    fileprivate static func hasAtLeastTwo(duo: Card.Duo, inHandOfPlayer playerUp: Player.ID) -> Self {
        .init { deck in
            deck.cards
                .filter({ $0.kind == .duo(duo) && $0.location == .playerHand(playerUp) })
                .count >= 2
        }
    }
}

// MARK: - Game Commands
extension Command where S == GameEngine {
    fileprivate static func playEffect(cards: (Card.ID, Card.ID)) -> Self {
        .init { gameEngine in
            // Move cards to played
            gameEngine.game.update(cardID: cards.0, toLocation: .playerEffects(gameEngine.game.currentPlayerUp))
            gameEngine.game.update(cardID: cards.1, toLocation: .playerEffects(gameEngine.game.currentPlayerUp))


            // Play the effect
            guard let (firstCard, secondCard) = gameEngine.effectCards(cardIDs: cards) else { return }

            // TODO: Implement effect
            switch (firstCard.kind, secondCard.kind) {
            case (.duo(.crab), .duo(.crab)): try playPairOfCrabs.execute(on: &gameEngine)
            case (.duo(.fish), .duo(.fish)): try playPairOfFish.execute(on: &gameEngine)
            case (.duo(.ship), .duo(.ship)): try playPairOfShips.execute(on: &gameEngine)
            case (.duo(.shark), .duo(.swimmer)),
                (.duo(.swimmer), .duo(.shark))
                : break // steal from player, needs player choice

            default: break
            }
        }
    }

    private static let playPairOfCrabs: Self = .init {
        // Needs user input so user will decide.
        $0.game.set(phase: .resolvingEffect(.pickUpDiscard))
    }

    private static let playSwimmerAndShark: Self = .init {
        // Needs user input so user will decide.
        $0.game.set(phase: .resolvingEffect(.stealCard))
    }

    private static let playPairOfShips: Self = .init {
        // Restart the user's turn
        $0.game.set(phase: .waitingForDraw)
    }

    private static let playPairOfFish: Self = .init {
        guard let card = try $0.game.draw(pile: .draw).first else { return }
        $0.game.update(cardID: card.id, toLocation: .playerHand($0.game.currentPlayerUp))
        $0.game.set(phase: .waitingForPlay)
    }

    fileprivate static func stealCard(cardID: Card.ID) -> Self {
        .init {
            $0.game.update(cardID: cardID, toLocation: .playerHand($0.game.currentPlayerUp))
            $0.game.set(phase: .waitingForPlay)
        }
    }
}

extension GameEngine {
    fileprivate func effectCards(cardIDs: (Card.ID, Card.ID)) -> (Card, Card)? {
        guard
            let firstCard = game.deck.cards.first(where: { $0.id == cardIDs.0 }),
            let secondCard = game.deck.cards.first(where: { $0.id == cardIDs.1 })
        else { return nil }
        return (firstCard, secondCard)
    }
}
