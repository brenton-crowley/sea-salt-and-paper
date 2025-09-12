import Foundation
import Models
import Repositories

extension GameState {
    struct DataProvider: Sendable {
        static let `default`: Self = .make(
            deckRepository: .live
        )

        var deck: @Sendable () -> [Card]
    }
}

extension GameState.DataProvider {
    static func make(
        deckRepository: DeckRepository
    ) -> Self {
        .init(
            deck: { deckRepository.deck.compactMap(Card.init(from:)) }
        )
    }
}

#if DEBUG

extension GameState.DataProvider {
    static var testValue: Self {
        .init(
            deck: { fatalError("Unimplemented") }
        )
    }
}

#endif
