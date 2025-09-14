import Foundation
import Models
import Repositories

extension GameState {
    struct DataProvider: Sendable {
        static let `default`: Self = .make(
            deckRepository: .live,
            playersInGameCount: .two
        )

        var deck: @Sendable () -> [Card]
        var playersInGameCount: @Sendable () -> Player.InGameCount
    }
}

extension GameState.DataProvider {
    static func make(
        deckRepository: DeckRepository,
        playersInGameCount: Player.InGameCount
    ) -> Self {
        .init(
            deck: { deckRepository.deck.compactMap(Card.init(from:)) },
            playersInGameCount: { playersInGameCount }
        )
    }
}

#if DEBUG

extension GameState.DataProvider {
    static var testValue: Self {
        .init(
            deck: { fatalError("Unimplemented") },
            playersInGameCount: { fatalError("Unimplemented") }
        )
    }
}

#endif
