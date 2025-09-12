import Foundation

// MARK: - Definition

extension Deck {
    public enum Pile: Sendable, Hashable, Identifiable {
        case draw, discardLeft, discardRight
        
        public var id: Pile { self }
    }
}

// MARK: - Computed Properties

extension Deck.Pile {
    public var drawNumber: Int {
        switch self {
        case .draw: 2
        case .discardLeft, .discardRight: 1
        }
    }
}


