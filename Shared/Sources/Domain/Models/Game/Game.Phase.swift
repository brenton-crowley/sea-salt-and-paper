import Foundation

// MARK: - Definition

extension Game {
    public enum Phase: Sendable, Hashable, Identifiable {
         case waitingForStart
         case waitingForDraw
         case waitingForDiscard
         case waitingForPlay
         case resolvingEffects
         case endTurn
         case endRound

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

