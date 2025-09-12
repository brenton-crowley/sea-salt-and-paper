import Foundation
import Repositories

// MARK: - Card Mappings from DeckRepository

extension Card {
    public init?(from deckRepositoryCard: DeckRepository.Card) {
        guard
            let kind = Card.Kind(from: deckRepositoryCard.kind, subType: deckRepositoryCard.subType),
            let color = Card.Color(from: deckRepositoryCard.color)
        else { return nil }

        self.init(
            id: deckRepositoryCard.id,
            kind: kind,
            color: color
        )
    }
}

extension Card.Kind {
    init?(from kindJSONKey: String, subType: String?) {
        switch kindJSONKey {
        case "multiplier":
            guard let multiplier = Models.Card.Multiplier(from: subType) else { return nil }
            self = .multiplier(multiplier)

        case "collector":
            guard let collector = Models.Card.Collector(from: subType) else { return nil }
            self = .collector(collector)

        case "duo":
            guard let duo = Models.Card.Duo(from: subType) else { return nil }
            self = .duo(duo)

        case "mermaid": self = .mermaid
        default: return nil
        }
    }
}

extension Card.Duo {
    init?(from jsonKey: String?) {
        switch jsonKey {
        case "fish": self = .fish
        case "ship": self = .ship
        case "crab": self = .crab
        case "swimmer": self = .swimmer
        case "shark": self = .shark
        default: return nil
        }
    }
}

extension Card.Collector {
    init?(from jsonKey: String?) {
        switch jsonKey {
        case "shell": self = .shell
        case "octopus": self = .octopus
        case "penguin": self = .penguin
        case "sailor": self = .sailor
        default: return nil
        }
    }
}

extension Card.Multiplier {
    init?(from jsonKey: String?) {
        switch jsonKey {
        case "ship": self = .ship
        case "fish": self = .fish
        case "penguin": self = .penguin
        case "sailor": self = .sailor
        default: return nil
        }
    }
}

extension Card.Color {
    init?(from jsonKey: String?) {
        switch jsonKey {
        case "dark-blue": self = .darkBlue
        case "light-blue": self = .lightBlue
        case "black": self = .black
        case "yellow": self = .yellow
        case "light-green": self = .lightGreen
        case "white": self = .white
        case "purple": self = .purple
        case "light-grey": self = .lightGrey
        case "light-orange": self = .lightOrange
        case "light-pink": self = .lightPink
        case "orange": self = .orange
        default: return nil
        }
    }
}
