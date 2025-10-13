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
    public enum EndTurn: Sendable, Hashable, Identifiable {
        public var id: Self { self }

        case nextPlayer
        case stop
        case lastChance
    }
    public enum User: Sendable, Hashable, Identifiable {
        case drawPilePickUp
        case pickUpFromLeftDiscard
        case pickUpFromRightDiscard
        case discardToRightPile(Card.ID)
        case discardToLeftPile(Card.ID)
        case playEffectWithCards(Card.ID, Card.ID)
        case stealCard(Card.ID)
        case endTurn(EndTurn)

        public var id: Self { self }
    }

    public enum System: Sendable, Hashable, Identifiable {
        case createGame(players: Player.InGameCount)

        public var id: Self { self }
    }
}

// MARK: - Computed Properties

extension GameEngine.Action {
}

// MARK: - Methods

extension GameEngine.Action {
}

extension GameEngine.Action.User {
    /// Maps a public facing case from ``GameEngine/GameEngine/Action/User`` to an internal command that can be performed on the game.
    var action: Action<Game> {
        switch self {
        case .drawPilePickUp: .pickUpFromDrawPile
        case .pickUpFromLeftDiscard: .pickUpFromLeftDiscardPile
        case .pickUpFromRightDiscard: .pickUpFromRightDiscardPile
        case let .discardToRightPile(cardID): .discardToRightPile(cardID: cardID)
        case let .discardToLeftPile(cardID): .discardToLeftPile(cardID: cardID)
        case let .playEffectWithCards(card1, card2): .playEffect(cards: (card1, card2))
        case let .stealCard(cardID): .stealCard(cardID: cardID)
        case .endTurn(.nextPlayer): .endTurnNextPlayer
        case .endTurn(.stop): .endTurnNextPlayer // TODO: Update
        case .endTurn(.lastChance): .endTurnNextPlayer // TODO: Update
        }
    }
}

extension GameEngine.Action.System {
    /// Maps a public facing case from ``GameEngine/GameEngine/Action/System`` to an internal command that can be performed on the game.
    var action: Action<GameEngine> {
        return switch self {
        case let .createGame(players): .createGame(players: players)
        }
    }
}

// MARK: - Mocks

#if DEBUG

extension GameEngine.Action {
}

#endif
