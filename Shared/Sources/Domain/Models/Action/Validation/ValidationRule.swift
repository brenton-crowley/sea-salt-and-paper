import Foundation

public struct ValidationRule<Input>: Sendable {
    var ruleIsValid: @Sendable (_ input: Input) -> Bool

    public init(rule: @Sendable @escaping (_ input: Input) -> Bool) {
        self.ruleIsValid = rule
    }
}

extension ValidationRule {
    public func validate(on input: Input) -> Bool {
        ruleIsValid(input)
    }
}
