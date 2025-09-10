import Foundation

// MARK: - Definition

extension Card {
    public enum Kind: Hashable, Sendable {
        case duo(Duo)
        case collector(Collector)
        case mermaid
        case multiplier(Multiplier)
    }
}


// MARK: - Computed Properties

extension Card.Kind {
}

// MARK: - Mapping

extension Card.Kind {
}

// MARK: - Mocks

#if DEBUG

extension Card.Kind {
}

#endif

