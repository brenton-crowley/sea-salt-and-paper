import Foundation

// MARK: - Definition

extension Card {
    public enum Multiplier: Hashable, Sendable {
        case ship
        case fish
        case penguin
        case sailor
    }
}


// MARK: - Computed Properties

extension Card.Multiplier {}

// MARK: - Mapping

extension Card.Multiplier {
}

// MARK: - Mocks

#if DEBUG

extension Card.Multiplier {
}

#endif

