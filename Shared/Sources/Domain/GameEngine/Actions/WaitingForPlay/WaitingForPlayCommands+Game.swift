import Foundation
import Models

// MARK: - Game Actions
extension Action where S == Game {
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

    static let endTurnNextPlayer: Self = .init(
        rule: .ruleToEndTurn,
        command: .endTurnNextPlayer
    )
    
    static let endTurnStop: Self = .init(rule: .ruleToEndTurnStop, command: .endTurnStopCommand)

}

// MARK: - Game Validations
extension ValidationRule where Input == Game {
    static func ruleToPlayEffect(cards: (Card.ID, Card.ID)) -> Self {
        .init {
            guard
                $0.phase(equals: .waitingForPlay),
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
                let card = $0.deck.cards.first(where: { $0.id == cardID }),
                case .playerHand = card.location
            else { return false }
            return true
        }
    }

    fileprivate static let hasPairOfCrabs: Self = .init {
        ValidationRule<Deck>.hasAtLeastTwo(duo: .crab, inHandOfPlayer: $0.currentPlayerUp)
            .validate(on: $0.deck)
    }

    fileprivate static let ruleToEndTurn: Self  = .init {
        guard $0.phase(equals: .waitingForPlay) else { return false }
        return true
    }
    
    // Keep it minimal for now: only legal while the current player is in the Play phase.
    // (We can tighten this later per your spreadsheet.)
    fileprivate static let ruleToEndTurnStop: Self  = .init {
        guard $0.phase(equals: .waitingForPlay) else { return false }
        return true
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
extension Command where S == Game {
    fileprivate static func playEffect(cards: (Card.ID, Card.ID)) -> Self {
        .init { game in
            // Move cards to played
            game.update(cardID: cards.0, toLocation: .playerEffects(game.currentPlayerUp))
            game.update(cardID: cards.1, toLocation: .playerEffects(game.currentPlayerUp))

            // Play the effect
            guard let (firstCard, secondCard) = game.effectCards(cardIDs: cards) else { return }

            switch (firstCard.kind, secondCard.kind) {
            case (.duo(.crab), .duo(.crab)): try playPairOfCrabs.execute(on: &game)
            case (.duo(.fish), .duo(.fish)): try playPairOfFish.execute(on: &game)
            case (.duo(.ship), .duo(.ship)): try playPairOfShips.execute(on: &game)
            case (.duo(.shark), .duo(.swimmer)),
                (.duo(.swimmer), .duo(.shark)): try playSwimmerAndShark.execute(on: &game)

            default: break
            }
        }
    }

    private static let playPairOfCrabs: Self = .init {
        // Needs user input so user will decide.
        $0.set(phase: .resolvingEffect(.pickUpDiscard))
    }

    private static let playSwimmerAndShark: Self = .init {
        // Needs user input so user will decide.
        $0.set(phase: .resolvingEffect(.stealCard))
    }

    private static let playPairOfShips: Self = .init {
        // Restart the user's turn
        $0.set(phase: .waitingForDraw)
    }

    private static let playPairOfFish: Self = .init {
        guard let card = try $0.draw(pile: .draw).first else { return }
        $0.update(cardID: card.id, toLocation: .playerHand($0.currentPlayerUp))
        $0.set(phase: .waitingForPlay)
    }

    fileprivate static func stealCard(cardID: Card.ID) -> Self {
        .init {
            $0.update(cardID: cardID, toLocation: .playerHand($0.currentPlayerUp))
            $0.set(phase: .waitingForPlay)
        }
    }

    fileprivate static let endTurnNextPlayer: Self = .init {
        // TODO: Need to check that we're not in last chance because if we are and next player called last chance, then it's the end of the round.
        // TODO: AI we may need to refactor out some of this logic based on the comment on the line above.

        $0.set(phase: .endTurn(.nextPlayer))

        // move this logic out.

        // Run the system actions.
        // - Check mermaids
        guard !$0.currentPlayerHasFourMermaids else {
            $0.set(phase: .endGame)
            return // End game
        }

        // Only change to next player so long as nextPlayerUp
        // $0.currentPlayerUp.next(playersInGame: )
        // -- Change to next player
        $0.setNextPlayerUp()
        $0.set(phase: .waitingForDraw)
    }

    fileprivate static let endTurnStopCommand: Self = .init {
        $0.set(phase: .endTurn(.stop))
        
        // Update the state on the round.
        $0.set(roundState: .endReason(.stop, caller: $0.currentPlayerUp))
        
        // Calculate the scores
        $0.set(roundPoints: ScoreCalculator.roundPointsForStop(cards: $0.deck.cards))
        
        // Check if there is a winner.
        if $0.winner != nil { $0.set(phase: .endGame) }
        
        // Ask user to start new round.
    }
}

extension Game {
    fileprivate func effectCards(cardIDs: (Card.ID, Card.ID)) -> (Card, Card)? {
        guard
            let firstCard = deck.cards.first(where: { $0.id == cardIDs.0 }),
            let secondCard = deck.cards.first(where: { $0.id == cardIDs.1 })
        else { return nil }
        return (firstCard, secondCard)
    }
}
