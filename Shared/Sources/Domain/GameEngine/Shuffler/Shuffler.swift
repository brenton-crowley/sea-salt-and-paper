import Foundation
import Models
import SharedDependency

struct Shuffler: Sendable {
    struct DataProvider: Sendable {
        var shuffleCards: @Sendable (_ cards: [Card]) -> [Card]
    }

    let dataProvider: Self.DataProvider

    func shuffle(cards: [Card]) -> [Card] {
        dataProvider.shuffleCards(cards)
    }
}

extension Shuffler: DependencyModeKey {
    public static let live: Self = .init(
        dataProvider: .init(
            shuffleCards: { $0.shuffled() }
        )
    )

    public static let mock: Self = .init(
        dataProvider: .init(shuffleCards: { $0 })
    )

    public static let mockError: Self = .init(
        dataProvider: .init(shuffleCards: { $0 })
    )
}

