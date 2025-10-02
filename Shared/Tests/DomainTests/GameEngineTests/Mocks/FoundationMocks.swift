import Foundation
import Models

extension UUID {
    static func mockGameID(_ id: Int = .mockID) -> Self { UUID.init(id) }
}

extension Int {
    static let mockID = 0

    static func number(of players: Player.InGameCount) -> Self {
        switch players {
        case .two: 2
        case .three: 3
        case .four: 4
        }
    }
}
