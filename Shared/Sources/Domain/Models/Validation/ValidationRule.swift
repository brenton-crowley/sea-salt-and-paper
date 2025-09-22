import Foundation

public struct ValidationRule: Sendable {
    var ruleIsValid: @Sendable (_ game: Game) -> Bool

    public init(rule: @Sendable @escaping (_ game: Game) -> Bool) {
        self.ruleIsValid = rule
    }
}

extension ValidationRule {
    public func validate(on game: Game) -> Bool {
        ruleIsValid(game)
    }
}
