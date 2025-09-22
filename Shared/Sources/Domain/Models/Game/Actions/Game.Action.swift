import Foundation

// MARK: - Definition

extension Game {
    public enum Action: Sendable, Hashable, Identifiable {
        case drawPilePickUp
        case pickUpFromLeftDiscard
        case pickUpFromPickUpDiscard
        case discardToRightPile(Card.ID)
        case discardToLeftPile(Card.ID)

        public var id: Self { self }
    }
}

// MARK: - Computed Properties

extension Game.Action {
    public var validationRule: ValidationRule {
        return switch self {
        case .drawPilePickUp: .ruleToPickUpFromDrawPile
        case .pickUpFromLeftDiscard: .drawFromLeftDiscardPile
        case .pickUpFromPickUpDiscard: .drawFromRightDiscardPile
        case let .discardToRightPile(cardID): .ruleToDiscard(cardID: cardID, onto: .discardRight)
        case let .discardToLeftPile(cardID): .ruleToDiscard(cardID: cardID, onto: .discardLeft)
        }
    }
}

// MARK: - Mapping

extension Game.Action {
}

// MARK: - Mocks

#if DEBUG

extension Game.Action {
}

#endif

