import Foundation

// MARK: - Definition

public enum Pile: Sendable, Hashable, Identifiable {
    case draw, discardLeft, discardRight

    public var id: Pile { self }
}

// MARK: - Computed Properties

extension Pile {
    public var drawNumber: Int {
        switch self {
        case .draw: 2
        case .discardLeft, .discardRight: 1
        }
    }
}

// MARK: - Methods

extension Pile {
}

// MARK: - Mocks

#if DEBUG

extension Pile {
}

#endif

