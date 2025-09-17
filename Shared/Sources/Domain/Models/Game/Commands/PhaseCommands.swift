import Foundation

extension Command where S == Game {
    static func changePhase(to phase: Game.Phase) -> Self {
        .init(execute: { $0.phase = phase })
    }
}
