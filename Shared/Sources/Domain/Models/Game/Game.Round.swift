import Foundation

// MARK: - Definition

extension Game {
    public struct Round: Sendable, Hashable, Identifiable {
        // public enum State {
        //     case inProgress
        //     case endTurn(kind: Game.EndRoundKind, player: Player.Up)
        //     case complete()
        // }

        public var id: Self { self }

    }
}

// MARK: - Computed Properties

extension Game.Round {}

// MARK: - Methods

extension Game.Round {

}

// MARK: - fileprivate Extensions
extension Int {
}

// MARK: - Mocks

#if DEBUG

extension Game.Round {
}

#endif

