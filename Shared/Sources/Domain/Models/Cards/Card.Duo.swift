import Foundation

// MARK: - Definition

extension Card {
    public enum Duo: Hashable, Sendable {
        case fish
        case ship
        case crab
        case swimmer
        case shark
    }
}


// MARK: - Computed Properties

extension Card.Duo {}

// MARK: - Mapping

extension Card.Duo {
}

// MARK: - Mocks

#if DEBUG

extension Card.Duo {
}

#endif

