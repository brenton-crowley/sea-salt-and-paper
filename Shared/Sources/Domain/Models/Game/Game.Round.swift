import Foundation

// MARK: - Definition

extension Game {
    public struct Round: Sendable, Hashable, Identifiable {
        public enum EndReason: Sendable, Hashable {
            case stop
            case lastChance
        }
        
        public enum State: Sendable, Hashable {
            case inProgress
            case endReason(Round.EndReason, caller: Player.ID)
            case complete
        }
        
        internal(set) public var state: Round.State = .inProgress
        internal(set) public var points: [Player.ID: Int] = [:]
        
        public var id: Self { self }
    }
}

// MARK: - Computed Properties

extension Game.Round {}

// MARK: - Methods

extension Game.Round {
    mutating func set(state: Self.State) {
        self.state = state
    }
    
    mutating func set(points: [Player.ID: Int]) {
        self.points = points
    }
}

// MARK: - fileprivate Extensions
extension Int {
}

// MARK: - Mocks

#if DEBUG

extension Game.Round {
}

#endif

