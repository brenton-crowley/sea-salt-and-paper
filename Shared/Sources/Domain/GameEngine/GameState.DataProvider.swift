import Dependencies
import Foundation
import Models
import Repositories

extension GameEngine {
    struct DataProvider: Sendable {
        static let `default`: Self = .make(
            deckRepository: .live,
            playersInGameCount: .two
        )

        var deck: @Sendable () -> [Card]
        var newGameID: @Sendable () -> Game.ID
    }
}

extension GameEngine.DataProvider {
    static func make(
        deckRepository: DeckRepository,
        playersInGameCount: Player.InGameCount
    ) -> Self {
        .init(
            deck: { deckRepository.deck.compactMap(Card.init(from:)) },
            newGameID: {
                @Dependency(\.uuid) var uuid
                return uuid()
            }
        )
    }
}

#if DEBUG

extension GameEngine.DataProvider {
    static var testValue: Self {
        .init(
            deck: { fatalError("Unimplemented") },
            newGameID: { fatalError("Unimplemented") }
        )
    }
}

#endif
