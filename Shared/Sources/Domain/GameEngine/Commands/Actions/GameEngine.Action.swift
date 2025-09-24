import Foundation
import Models

// MARK: - Definition

extension GameEngine {
    public enum Action: Sendable, Hashable, Identifiable {
        case user(Action.User)
        case system(Action.System)

        public var id: Self { self }
    }
}

extension GameEngine.Action {
    public enum User: Sendable, Hashable, Identifiable {
        case drawPilePickUp
        case pickUpFromLeftDiscard
        case pickUpFromRightDiscard
        case discardToRightPile(Card.ID)
        case discardToLeftPile(Card.ID)

        public var id: Self { self }
    }

    public enum System: Sendable, Hashable, Identifiable {
        case createGame(players: Player.InGameCount)
        case prepareDeckForPlay

        public var id: Self { self }
    }
}

// MARK: - Computed Properties

extension GameEngine.Action {
    var validationRule: ValidationRule<Game> {
        return switch self {
        case .user(.drawPilePickUp): .ruleToPickUpFromDrawPile
        case .user(.pickUpFromLeftDiscard): .ruleToDrawFromLeftDiscardPile
        case .user(.pickUpFromRightDiscard): .ruleToDrawFromRightDiscardPile
        case let .user(.discardToRightPile(cardID)): .ruleToDiscard(cardID: cardID, onto: .discardRight)
        case let .user(.discardToLeftPile(cardID)): .ruleToDiscard(cardID: cardID, onto: .discardLeft)
        case .system(.createGame): .ruleToCreateGame // TODO: Change
        case .system(.prepareDeckForPlay): .ruleToCreateGame
        }
    }
}

// MARK: - Methods

extension GameEngine.Action {

}

extension GameEngine.Action.User {
    func play(on game: inout Game) throws {
        switch self {
        case .drawPilePickUp: try executeThrowingCommand(.pickUpFromDrawPile(), on: &game)
        case .pickUpFromLeftDiscard: try executeThrowingCommand(.pickUpFromDiscardLeftPile(), on: &game)
        case .pickUpFromRightDiscard: try executeThrowingCommand(.pickUpFromDiscardRightPile(), on: &game)
        case let .discardToLeftPile(cardID): executeCommand(.discardToLeftPile(cardID: cardID), on: &game)
        case let .discardToRightPile(cardID): executeCommand(.discardToRightPile(cardID: cardID), on: &game)
        }
    }

    private func executeCommand(_ command: Command<Game>, on game: inout Game) {
        command.execute(on: &game)
    }

    private func executeThrowingCommand(_ command: ThrowingCommand<Game>, on game: inout Game) throws {
        try command.execute(on: &game)
    }
}

extension GameEngine.Action.System {
    
}

// MARK: - Mocks

#if DEBUG

extension GameEngine.Action {
}

#endif

extension Action where S == Game {
    static func distributeFirstTwoCardsToDiscardPiles() -> Self {
        .init(
            rule: {
                .init { game in
                    guard
                        game.phase(equals: .waitingForStart),
                        game.deck.leftDiscardPile.isEmpty,
                        game.deck.rightDiscardPile.isEmpty
                    else { return false }

                    return true
                }
            },
            command: {
                .init { game in
                    let cards = try game.draw(pile: .draw)
                    guard
                        let firstCard = cards.first,
                        let lastCard = cards.last
                    else { return }

                    game.update(cardID: firstCard.id, toLocation: .pile(.discardLeft))
                    game.update(cardID: lastCard.id, toLocation: .pile(.discardRight))
                }
            }
        )
    }
}
