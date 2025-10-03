import Foundation

// MARK: - Definition

extension Game {
    public enum Effect: Sendable, Hashable, Identifiable {
        case pickUpDiscard // Needs player input
        case stealCard // Needs player input

        public var id: Self { self }
    }

    public enum EndRoundKind: Sendable, Hashable, Identifiable {
        case stop
        case lastChance

        public var id: Self { self }
    }

    public enum Phase: Sendable, Hashable, Identifiable {
        case waitingForStart
        case waitingForDraw
        case waitingForDiscard
        case waitingForPlay
        case resolvingEffect(Game.Effect)
        case endTurn
        case endRound(Game.EndRoundKind)
        case endGame

        public var id: Self { self }
    }
}

// MARK: - Computed Properties

extension Game.Phase {}

// MARK: - Mapping

extension Game.Phase {
}

// MARK: - Mocks

#if DEBUG

extension Game.Phase {
}

#endif

