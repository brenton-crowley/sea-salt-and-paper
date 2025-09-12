import Foundation

// MARK: - Definition

extension Player {
    public enum Number: Sendable, Hashable, CaseIterable {
        case one, two, three, four
    }
}

extension Player.Number {
    public func next() -> Self {
        guard
            let selfIndex = Self.allCases.firstIndex(of: self),
            Self.allCases.indices.contains(Self.allCases.index(after: selfIndex))
        else { return Self.allCases[0] }

        return Self.allCases[Self.allCases.index(after: selfIndex)]
    }
}
