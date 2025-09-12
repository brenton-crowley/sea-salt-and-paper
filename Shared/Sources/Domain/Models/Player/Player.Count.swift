import Foundation

// MARK: - Definition

extension Player {
    public enum MaxCount: Sendable, Hashable, CaseIterable {
        case two, three, four
    }
}

extension Player.MaxCount {
}
