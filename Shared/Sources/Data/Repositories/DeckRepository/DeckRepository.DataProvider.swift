import Foundation
import SharedBundle

extension DeckRepository {
    struct DataProvider: Sendable {
        var deckData: @Sendable () throws -> Data

        static func make(moduleBundle: SharedBundle) -> Self {
            .init(
                deckData: {
                    guard let url = moduleBundle.url(forResource: .deck, withExtension: .jsonExtension) else { throw URLError(.badURL) }

                    return try Data(contentsOf: url)
                }
            )
        }
    }
}

extension DeckRepository.DataProvider {
    static let `default`: Self = .make(moduleBundle: .live(bundle: .module))
}

extension String {
    static let deck = "sea-salt-and-paper-deck"
    static let jsonExtension = "json"
}
