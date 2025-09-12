import Repositories
import Foundation
import Testing

struct DeckRepositoryTests {
    @Test("Bundle JSON - Contains 58 Cards")
    func shouldContain58Cards() {
        // GIVEN
        let testSubject = DeckRepository.live

        // WHEN
        let deck = testSubject.deck

        // THEN
        #expect(deck.count == 58)
    }

    @Test("Colors")
    func deckColors() {
        // GIVEN
        let testSubject = DeckRepository.live

        // WHEN
        let deckColors = testSubject.deck.map(\.color)

        // THEN

        #expect(deckColors.filter({ $0 == "dark-blue" }).count == 9)
        #expect(deckColors.filter({ $0 == "light-blue" }).count == 9)
        #expect(deckColors.filter({ $0 == "black" }).count == 8)
        #expect(deckColors.filter({ $0 == "yellow" }).count == 8)
        #expect(deckColors.filter({ $0 == "light-green" }).count == 6)
        #expect(deckColors.filter({ $0 == "white" }).count == 4)
        #expect(deckColors.filter({ $0 == "purple" }).count == 4)
        #expect(deckColors.filter({ $0 == "light-grey" }).count == 4)
        #expect(deckColors.filter({ $0 == "light-orange" }).count == 3)
        #expect(deckColors.filter({ $0 == "light-pink" }).count == 2)
        #expect(deckColors.filter({ $0 == "orange" }).count == 1)
    }

    @Test("Card Kinds")
    func deckKinds() {
        // GIVEN
        let testSubject = DeckRepository.live

        // WHEN
        let deckKinds = testSubject.deck.map { (kind: $0.kind, subType: $0.subType) }

        // THEN
        // Mermaids
        #expect(deckKinds.filter({ $0.kind == .mermaid && $0.subType == nil}).count == 4)

        // Collectors
        #expect(deckKinds.filter({ $0.kind == .collector && $0.subType == .sailor}).count == 2)
        #expect(deckKinds.filter({ $0.kind == .collector && $0.subType == .penguin}).count == 3)
        #expect(deckKinds.filter({ $0.kind == .collector && $0.subType == .octopus}).count == 5)
        #expect(deckKinds.filter({ $0.kind == .collector && $0.subType == .shell}).count == 6)

        // Multipliers
        #expect(deckKinds.filter({ $0.kind == .multiplier && $0.subType == .fish}).count == 1)
        #expect(deckKinds.filter({ $0.kind == .multiplier && $0.subType == .ship}).count == 1)
        #expect(deckKinds.filter({ $0.kind == .multiplier && $0.subType == .penguin}).count == 1)
        #expect(deckKinds.filter({ $0.kind == .multiplier && $0.subType == .sailor}).count == 1)

        // Duos
        #expect(deckKinds.filter({ $0.kind == .duo && $0.subType == .crab}).count == 9)
        #expect(deckKinds.filter({ $0.kind == .duo && $0.subType == .ship}).count == 8)
        #expect(deckKinds.filter({ $0.kind == .duo && $0.subType == .fish}).count == 7)
        #expect(deckKinds.filter({ $0.kind == .duo && $0.subType == .swimmer}).count == 5)
        #expect(deckKinds.filter({ $0.kind == .duo && $0.subType == .shark}).count == 5)
    }
}
