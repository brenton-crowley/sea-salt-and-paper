import Foundation
import IssueReporting
import Models
import Repositories
import SharedID

extension GameEngine {
    struct DataProvider: Sendable {
        static let `default`: Self = .make(
            deckRepository: .live,
            playersInGameCount: .two,
            shuffler: .live,
            uuidService: .live
        )

        var deck: @Sendable () -> [Card]
        var newGameID: @Sendable () -> Game.ID
        var saveGame: @Sendable (_ game: Game) -> Void
        var shuffleCards: @Sendable (_ cards: [Card]) -> [Card]
    }
}

extension GameEngine.DataProvider {
    static func make(
        deckRepository: DeckRepository,
        playersInGameCount: Player.InGameCount,
        shuffler: Shuffler,
        uuidService: UUIDService
    ) -> Self {
        .init(
            deck: { deckRepository.deck.compactMap(Card.init(from:)) },
            newGameID: { uuidService.generateUUID() },
            saveGame: { _ in print("\(#function) - Implement save game in \(Self.self)")  },
            shuffleCards: { shuffler.shuffle(cards: $0) }
        )
    }
}

#if DEBUG

extension GameEngine.DataProvider {
    static var testValue: Self {
        .init(
            deck: { fatalError("Unimplemented") },
            newGameID: { fatalError("Unimplemented") },
            saveGame: { _ in fatalError("Unimplemented") },
            shuffleCards: { _ in fatalError("Unimplemented") }
        )
    }
}

#endif
