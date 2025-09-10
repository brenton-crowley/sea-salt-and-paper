import Foundation

// MARK: - Definition

extension Card {
    public enum Collector: Hashable, Sendable {
        case shell
        case octopus
        case penguin
        case sailor
    }
}


// MARK: - Computed Properties

extension Card.Collector {}

// MARK: - Mapping

extension Card.Collector {
}

// MARK: - Mocks

#if DEBUG

extension Card.Collector {
}

#endif

