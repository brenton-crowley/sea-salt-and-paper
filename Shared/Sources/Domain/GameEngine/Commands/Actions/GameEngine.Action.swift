import Foundation
import Models

// MARK: - Definition

extension GameEngine {
    public enum Action: Sendable, Hashable, Identifiable {
        case user(Action.User)

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
        }
    }
}

// MARK: - Methods

extension GameEngine.Action {
    func play(on game: inout Game) throws {
        switch self {
        case .user(.drawPilePickUp): try executeThrowingCommand(.pickUpFromDrawPile(), on: &game)
        case .user(.pickUpFromLeftDiscard): try executeThrowingCommand(.pickUpFromDiscardLeftPile(), on: &game)
        case .user(.pickUpFromRightDiscard): try executeThrowingCommand(.pickUpFromDiscardRightPile(), on: &game)
        case let .user(.discardToLeftPile(cardID)): executeCommand(.discardToLeftPile(cardID: cardID), on: &game)
        case let .user(.discardToRightPile(cardID)): executeCommand(.discardToRightPile(cardID: cardID), on: &game)
        }
    }

    private func executeCommand(_ command: Command<Game>, on game: inout Game) {
        command.execute(on: &game)
    }

    private func executeThrowingCommand(_ command: ThrowingCommand<Game>, on game: inout Game) throws {
        try command.execute(on: &game)
    }
}

extension GameEngine.Action.User {
}

// MARK: - Mocks

#if DEBUG

extension GameEngine.Action {
}

#endif

