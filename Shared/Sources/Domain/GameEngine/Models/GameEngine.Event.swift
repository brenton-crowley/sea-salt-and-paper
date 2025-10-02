import Foundation
import Models

// MARK: - Definition

extension GameEngine {
    public enum Event: Sendable, Hashable {
        case updatedGame(Game)
    }
}

// MARK: - Computed Properties

extension GameEngine.Event {}

