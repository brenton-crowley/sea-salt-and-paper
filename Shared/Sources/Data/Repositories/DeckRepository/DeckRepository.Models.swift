import Foundation

extension DeckRepository {
    public struct Deck: Codable, Sendable {
        public let cards: [Card]
    }

    public struct Card: Codable, Identifiable, Sendable {
        public let id: Int
        public let kind: String
        public let subType: String?
        public let color: String
    }
}

extension String {
    public static let mermaid = "mermaid"
    public static let collector = "collector"
    public static let multiplier = "multiplier"
    public static let duo = "duo"

    public static let sailor = "sailor"
    public static let penguin = "penguin"
    public static let octopus = "octopus"
    public static let shell = "shell"

    public static let crab = "crab"
    public static let fish = "fish"
    public static let ship = "ship"
    public static let swimmer = "swimmer"
    public static let shark = "shark"
}

#if DEBUG

extension DeckRepository.Deck {
    static func mock(cards: [DeckRepository.Card] = .mock) -> Self {
        .init(cards: cards)
    }
}

extension Array where Element == DeckRepository.Card {
    static let mock: Self = [
        .mock(id: 1, kind: "duo", subType: "crab", color: "black"),
        .mock(id: 2, kind: "collector", subType: "octopus", color: "yellow"),
        .mock(id: 3, kind: "multiplier", subType: "penguin", color: "light-blue"),
    ]
}

extension DeckRepository.Card {
    static func mock(
        id: Int = 1,
        kind: String = "duo",
        subType: String? = "crab",
        color: String = "black"
    ) -> Self {
        .init(
            id: id,
            kind: kind,
            subType: subType,
            color: color
        )
    }
}

extension Data {
    static let mockDeckData: Self = """
        {
            "cards": [
                {
                    "id": 1,
                    "kind": "multiplier",
                    "subType": "fish",
                    "color": "light-grey"
                },
                {
                    "id": 2,
                    "kind": "multiplier",
                    "subType": "ship",
                    "color": "purple"
                },
                {
                    "id": 3,
                    "kind": "multiplier",
                    "subType": "penguin",
                    "color": "light-green"
                },
                {
                    "id": 4,
                    "kind": "multiplier",
                    "subType": "sailor",
                    "color": "light-orange"
                },
                {
                    "id": 5,
                    "kind": "mermaid",
                    "subType": null,
                    "color": "white"
                },
                {
                    "id": 9,
                    "kind": "collector",
                    "subType": "sailor",
                    "color": "orange"
                },
                {
                    "id": 11,
                    "kind": "collector",
                    "subType": "octopus",
                    "color": "light-grey"
                },
                {
                    "id": 16,
                    "kind": "collector",
                    "subType": "shell",
                    "color": "yellow"
                },
                {
                    "id": 22,
                    "kind": "collector",
                    "subType": "penguin",
                    "color": "purple"
                },
                {
                    "id": 25,
                    "kind": "duo",
                    "subType": "crab",
                    "color": "light-grey"
                },
                {
                    "id": 34,
                    "kind": "duo",
                    "subType": "ship",
                    "color": "yellow"
                },
                {
                    "id": 42,
                    "kind": "duo",
                    "subType": "fish",
                    "color": "yellow"
                },
                {
                    "id": 49,
                    "kind": "duo",
                    "subType": "shark",
                    "color": "dark-blue"
                },
                {
                    "id": 54,
                    "kind": "duo",
                    "subType": "swimmer",
                    "color": "light-blue"
                }
            ]
        }

        """.data(using: .utf8)!
}

#endif
