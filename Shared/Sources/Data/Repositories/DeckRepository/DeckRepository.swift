import Foundation
import SharedDependency
import SharedLogger

public struct DeckRepository: Sendable {
    let dataProvider: Self.DataProvider
    let logger = Logger(for: Self.self)

    public let deck: [Card]
    // public var allCards: Dictionary<Card.ID, Card>.Values { deck.values }

    init(dataProvider: Self.DataProvider) {
        self.dataProvider = dataProvider
        var deck: [Card] = []

        do {
            deck = try JSONDecoder().decode(
                DeckRepository.Deck.self,
                from: dataProvider.deckData()
            ).cards

        } catch {
            logger.error("\(#function) - Error: \(error)")
        }

        self.deck = deck
    }
}

extension DeckRepository: DependencyModeKey {
    public static let live: Self = .init(dataProvider: .default)

    public static let mock: Self = .live

    public static let mockError: Self = .init(
        dataProvider: .init(
            deckData: { throw MockError() }
        )
    )
}

